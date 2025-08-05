#!/usr/bin/env bash

# Claude Memento Compression System
# Cross-platform compatible (Windows/macOS/Linux, bash/zsh)

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/logger.sh"

# Compression configuration
COMPRESSION_ENABLED="${MEMENTO_COMPRESSION:-true}"
COMPRESSION_LEVEL="${MEMENTO_COMPRESSION_LEVEL:-6}"        # 1-9 (default 6)
COMPRESSION_AGE="${MEMENTO_COMPRESSION_AGE:-7}"            # 7일 이상된 파일 압축
COMPRESSION_MIN_SIZE="${MEMENTO_COMPRESSION_MIN_SIZE:-1024}" # 1KB 이상만 압축
COMPRESSION_BACKUP="${MEMENTO_COMPRESSION_BACKUP:-true}"   # 압축 전 백업

# Supported compression methods by priority
COMPRESSION_METHODS=("gzip" "bzip2" "xz" "compress" "zip")

# Detect available compression method
detect_compression_method() {
    for method in "${COMPRESSION_METHODS[@]}"; do
        case "$method" in
            gzip)
                if has_command gzip && has_command gunzip; then
                    echo "gzip"
                    return 0
                fi
                ;;
            bzip2)
                if has_command bzip2 && has_command bunzip2; then
                    echo "bzip2"
                    return 0
                fi
                ;;
            xz)
                if has_command xz && has_command unxz; then
                    echo "xz"
                    return 0
                fi
                ;;
            compress)
                if has_command compress && has_command uncompress; then
                    echo "compress"
                    return 0
                fi
                ;;
            zip)
                if has_command zip && has_command unzip; then
                    echo "zip"
                    return 0
                fi
                ;;
        esac
    done
    
    echo "none"
    return 1
}

# Get compression method
COMPRESSION_METHOD=$(detect_compression_method)

# Initialize compression system
init_compression() {
    if [ "$COMPRESSION_ENABLED" != "true" ]; then
        log_debug "Compression disabled"
        return 0
    fi
    
    if [ "$COMPRESSION_METHOD" = "none" ]; then
        log_warn "No compression tools available"
        COMPRESSION_ENABLED="false"
        return 1
    fi
    
    log_info "Compression initialized: $COMPRESSION_METHOD"
    return 0
}

# Check if file is already compressed
is_compressed() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Check by file extension
    case "$file" in
        *.gz|*.gzip)    return 0 ;;
        *.bz2|*.bzip2)  return 0 ;;
        *.xz)           return 0 ;;
        *.Z)            return 0 ;;
        *.zip)          return 0 ;;
    esac
    
    # Check by file header (magic numbers)
    if has_command file; then
        local file_type=$(file "$file" 2>/dev/null)
        case "$file_type" in
            *gzip*|*compressed*)
                return 0
                ;;
        esac
    fi
    
    # Check first few bytes
    if has_command hexdump; then
        local header=$(hexdump -C "$file" | head -n 1 | cut -d' ' -f2-3)
        case "$header" in
            "1f 8b"|"1f 9d"|"42 5a"|"fd 37"|"50 4b")
                return 0
                ;;
        esac
    fi
    
    return 1
}

# Get compression extension for method
get_compression_extension() {
    local method="$1"
    
    case "$method" in
        gzip)       echo ".gz" ;;
        bzip2)      echo ".bz2" ;;
        xz)         echo ".xz" ;;
        compress)   echo ".Z" ;;
        zip)        echo ".zip" ;;
        *)          echo ".compressed" ;;
    esac
}

# Compress file
compress_file() {
    local file="$1"
    local force="${2:-false}"
    local method="${3:-$COMPRESSION_METHOD}"
    
    if [ "$COMPRESSION_ENABLED" != "true" ]; then
        log_debug "Compression disabled"
        return 0
    fi
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Check if already compressed
    if is_compressed "$file"; then
        log_debug "File already compressed: $file"
        return 0
    fi
    
    # Check file size
    local size=$(get_file_size "$file")
    if [ "$size" -lt "$COMPRESSION_MIN_SIZE" ] && [ "$force" != "true" ]; then
        log_debug "File too small for compression: $file ($size bytes)"
        return 0
    fi
    
    # Check file age (if not forced)
    if [ "$force" != "true" ]; then
        local mtime=$(get_file_mtime "$file")
        local current_time=$(date +%s)
        local age_days=$(( (current_time - mtime) / 86400 ))
        
        if [ "$age_days" -lt "$COMPRESSION_AGE" ]; then
            log_debug "File too recent for compression: $file ($age_days days)"
            return 0
        fi
    fi
    
    log_info "Compressing file: $file (method: $method)"
    
    # Create backup if enabled
    local backup_file=""
    if [ "$COMPRESSION_BACKUP" = "true" ]; then
        backup_file="${file}.bak"
        if ! cp "$file" "$backup_file"; then
            log_error "Failed to create backup: $backup_file"
            return 1
        fi
    fi
    
    # Perform compression
    local extension=$(get_compression_extension "$method")
    local compressed_file="${file}${extension}"
    local original_size=$size
    local success=false
    
    case "$method" in
        gzip)
            if gzip -c -"$COMPRESSION_LEVEL" "$file" > "$compressed_file"; then
                success=true
            fi
            ;;
        bzip2)
            if bzip2 -c -"$COMPRESSION_LEVEL" "$file" > "$compressed_file"; then
                success=true
            fi
            ;;
        xz)
            if xz -c -"$COMPRESSION_LEVEL" "$file" > "$compressed_file"; then
                success=true
            fi
            ;;
        compress)
            if compress -c "$file" > "$compressed_file"; then
                success=true
            fi
            ;;
        zip)
            if zip -q -"$COMPRESSION_LEVEL" "$compressed_file" "$file"; then
                success=true
            fi
            ;;
        *)
            log_error "Unsupported compression method: $method"
            success=false
            ;;
    esac
    
    if [ "$success" = "true" ] && [ -f "$compressed_file" ]; then
        local compressed_size=$(get_file_size "$compressed_file")
        
        # Check if compression was effective
        if [ "$compressed_size" -ge "$original_size" ]; then
            log_warn "Compression not effective, keeping original: $file"
            rm -f "$compressed_file"
            success=false
        else
            # Calculate compression ratio
            local ratio=$(( 100 - (compressed_size * 100 / original_size) ))
            
            # Preserve metadata
            preserve_file_metadata "$file" "$compressed_file"
            
            # Remove original file
            rm -f "$file"
            
            log_success "Compression completed: $file -> $compressed_file (${ratio}% saved)"
            
            # Log compression stats
            log_compression_stats "$file" "$original_size" "$compressed_size" "$method"
        fi
    else
        log_error "Compression failed: $file"
        success=false
    fi
    
    # Cleanup backup on success, restore on failure
    if [ -n "$backup_file" ]; then
        if [ "$success" = "true" ]; then
            rm -f "$backup_file"
        else
            if [ ! -f "$file" ] && [ -f "$backup_file" ]; then
                mv "$backup_file" "$file"
                log_info "Restored from backup: $file"
            fi
        fi
    fi
    
    [ "$success" = "true" ]
}

# Decompress file
decompress_file() {
    local file="$1"
    local output_file="$2"
    local keep_compressed="${3:-false}"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # If not compressed, just copy or output
    if ! is_compressed "$file"; then
        if [ -n "$output_file" ]; then
            cp "$file" "$output_file"
        else
            cat "$file"
        fi
        return 0
    fi
    
    log_debug "Decompressing file: $file"
    
    # Determine compression method by extension and content
    local method=""
    case "$file" in
        *.gz|*.gzip)
            method="gzip"
            ;;
        *.bz2|*.bzip2)
            method="bzip2"
            ;;
        *.xz)
            method="xz"
            ;;
        *.Z)
            method="compress"
            ;;
        *.zip)
            method="zip"
            ;;
        *)
            # Try to detect by content
            if has_command file; then
                local file_type=$(file "$file" 2>/dev/null)
                case "$file_type" in
                    *gzip*)     method="gzip" ;;
                    *bzip2*)    method="bzip2" ;;
                    *XZ*)       method="xz" ;;
                    *compress*) method="compress" ;;
                    *Zip*)      method="zip" ;;
                esac
            fi
            ;;
    esac
    
    if [ -z "$method" ]; then
        log_error "Cannot determine compression method for: $file"
        return 1
    fi
    
    # Decompress based on method
    local success=false
    local temp_output=""
    
    if [ -z "$output_file" ]; then
        # Output to stdout
        case "$method" in
            gzip)
                gunzip -c "$file" && success=true
                ;;
            bzip2)
                bunzip2 -c "$file" && success=true
                ;;
            xz)
                unxz -c "$file" && success=true
                ;;
            compress)
                uncompress -c "$file" && success=true
                ;;
            zip)
                unzip -p "$file" && success=true
                ;;
        esac
    else
        # Output to file
        case "$method" in
            gzip)
                gunzip -c "$file" > "$output_file" && success=true
                ;;
            bzip2)
                bunzip2 -c "$file" > "$output_file" && success=true
                ;;
            xz)
                unxz -c "$file" > "$output_file" && success=true
                ;;
            compress)
                uncompress -c "$file" > "$output_file" && success=true
                ;;
            zip)
                unzip -p "$file" > "$output_file" && success=true
                ;;
        esac
        
        if [ "$success" = "true" ]; then
            # Preserve metadata
            preserve_file_metadata "$file" "$output_file"
            log_success "Decompressed: $file -> $output_file"
        fi
    fi
    
    if [ "$success" != "true" ]; then
        log_error "Decompression failed: $file"
        return 1
    fi
    
    # Remove compressed file if requested
    if [ "$keep_compressed" != "true" ] && [ -n "$output_file" ]; then
        rm -f "$file"
        log_debug "Removed compressed file: $file"
    fi
    
    return 0
}

# Preserve file metadata
preserve_file_metadata() {
    local source="$1"
    local target="$2"
    
    if [ ! -f "$source" ] || [ ! -f "$target" ]; then
        return 1
    fi
    
    # Preserve modification time
    case "$OS_TYPE" in
        macos)
            local mtime=$(stat -f %m "$source" 2>/dev/null)
            if [ -n "$mtime" ]; then
                touch -t $(date -r "$mtime" +%Y%m%d%H%M.%S) "$target" 2>/dev/null || true
            fi
            ;;
        linux|wsl)
            local mtime=$(stat -c %Y "$source" 2>/dev/null)
            if [ -n "$mtime" ]; then
                touch -d "@$mtime" "$target" 2>/dev/null || true
            fi
            ;;
        windows)
            # Best effort on Windows
            touch -r "$source" "$target" 2>/dev/null || true
            ;;
    esac
}

# Auto-compress old checkpoints
auto_compress_checkpoints() {
    local days="${1:-$COMPRESSION_AGE}"
    local count=0
    local saved_bytes=0
    
    if [ "$COMPRESSION_ENABLED" != "true" ]; then
        log_debug "Auto-compression disabled"
        return 0
    fi
    
    log_info "Auto-compressing checkpoints older than $days days..."
    
    local checkpoints_dir="$MEMENTO_DIR/checkpoints"
    if [ ! -d "$checkpoints_dir" ]; then
        log_debug "Checkpoints directory not found: $checkpoints_dir"
        return 0
    fi
    
    # Find old checkpoints
    local old_files=""
    case "$OS_TYPE" in
        macos)
            old_files=$(find "$checkpoints_dir" -name "*.md" -type f -mtime +"$days" 2>/dev/null || true)
            ;;
        linux|wsl)
            old_files=$(find "$checkpoints_dir" -name "*.md" -type f -mtime +"$days" 2>/dev/null || true)
            ;;
        windows)
            # Fallback: check file dates manually
            for file in "$checkpoints_dir"/*.md; do
                if [ -f "$file" ]; then
                    local mtime=$(get_file_mtime "$file")
                    local current_time=$(date +%s)
                    local age_days=$(( (current_time - mtime) / 86400 ))
                    
                    if [ "$age_days" -gt "$days" ]; then
                        old_files="$old_files$file\n"
                    fi
                fi
            done
            ;;
    esac
    
    if [ -z "$old_files" ]; then
        log_debug "No old checkpoints found for compression"
        return 0
    fi
    
    # Compress each old file
    echo "$old_files" | while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            local before_size=$(get_file_size "$file")
            
            if compress_file "$file" "true"; then
                local compressed_file="${file}.gz"  # Default to gzip extension
                local after_size=0
                
                # Find the actual compressed file
                for ext in .gz .bz2 .xz .Z .zip; do
                    if [ -f "${file}${ext}" ]; then
                        compressed_file="${file}${ext}"
                        after_size=$(get_file_size "$compressed_file")
                        break
                    fi
                done
                
                local saved=$((before_size - after_size))
                saved_bytes=$((saved_bytes + saved))
                count=$((count + 1))
                
                log_debug "Compressed: $(basename "$file") -> $(basename "$compressed_file")"
            fi
        fi
    done
    
    if [ "$count" -gt 0 ]; then
        log_success "Auto-compression completed: $count files, $(format_size $saved_bytes) saved"
    else
        log_debug "No files were compressed"
    fi
}

# Get compression statistics
get_compression_stats() {
    local checkpoints_dir="$MEMENTO_DIR/checkpoints"
    local total_files=0
    local compressed_files=0
    local total_original_size=0
    local total_compressed_size=0
    
    if [ ! -d "$checkpoints_dir" ]; then
        echo "Checkpoints directory not found"
        return 1
    fi
    
    # Scan all files in checkpoints directory
    for file in "$checkpoints_dir"/*; do
        if [ -f "$file" ]; then
            total_files=$((total_files + 1))
            local size=$(get_file_size "$file")
            
            if is_compressed "$file"; then
                compressed_files=$((compressed_files + 1))
                total_compressed_size=$((total_compressed_size + size))
                
                # Estimate original size (very rough estimate)
                # Typical compression ratio is 60-80%, so multiply by 2.5-3
                local estimated_original=$((size * 3))
                total_original_size=$((total_original_size + estimated_original))
            else
                total_original_size=$((total_original_size + size))
                total_compressed_size=$((total_compressed_size + size))
            fi
        fi
    done
    
    # Calculate compression ratio
    local compression_ratio=0
    if [ "$total_original_size" -gt 0 ]; then
        compression_ratio=$(( 100 - (total_compressed_size * 100 / total_original_size) ))
    fi
    
    echo "${BLUE}📦 Compression Statistics${NC}"
    echo "========================"
    echo "Total files: $total_files"
    echo "Compressed files: $compressed_files"
    echo "Estimated original size: $(format_size $total_original_size)"
    echo "Current size: $(format_size $total_compressed_size)"
    echo "Compression ratio: ${compression_ratio}%"
    echo "Space saved: $(format_size $((total_original_size - total_compressed_size)))"
    echo "Compression method: $COMPRESSION_METHOD"
    echo "Compression enabled: $COMPRESSION_ENABLED"
}

# Log compression statistics
log_compression_stats() {
    local original_file="$1"
    local original_size="$2"
    local compressed_size="$3"
    local method="$4"
    
    local stats_file="$MEMENTO_DIR/logs/compression-stats.log"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local ratio=$(( 100 - (compressed_size * 100 / original_size) ))
    
    mkdir -p "$(dirname "$stats_file")"
    
    {
        echo "[$timestamp] COMPRESS: $(basename "$original_file")"
        echo "  Method: $method"
        echo "  Original: $(format_size $original_size)"
        echo "  Compressed: $(format_size $compressed_size)"
        echo "  Ratio: ${ratio}%"
        echo "  Saved: $(format_size $((original_size - compressed_size)))"
        echo "---"
    } >> "$stats_file"
}

# Transparent read (handles compressed files automatically)
read_checkpoint_transparent() {
    local file="$1"
    
    # First try exact file
    if [ -f "$file" ]; then
        decompress_file "$file"
        return $?
    fi
    
    # Try with compression extensions
    for ext in .gz .bz2 .xz .Z .zip; do
        if [ -f "${file}${ext}" ]; then
            decompress_file "${file}${ext}"
            return $?
        fi
    done
    
    log_error "Checkpoint not found: $file"
    return 1
}

# Compression system status
compression_status() {
    echo "${BLUE}📦 Compression System Status${NC}"
    echo "============================"
    
    echo "Enabled: $COMPRESSION_ENABLED"
    echo "Method: $COMPRESSION_METHOD"
    echo "Level: $COMPRESSION_LEVEL"
    echo "Min size: $(format_size $COMPRESSION_MIN_SIZE)"
    echo "Auto-compress age: $COMPRESSION_AGE days"
    echo "Backup before compress: $COMPRESSION_BACKUP"
    
    echo -e "\n${CYAN}Available compression tools:${NC}"
    for method in "${COMPRESSION_METHODS[@]}"; do
        case "$method" in
            gzip)
                if has_command gzip; then
                    echo "  ✅ gzip/gunzip"
                else
                    echo "  ❌ gzip/gunzip"
                fi
                ;;
            bzip2)
                if has_command bzip2; then
                    echo "  ✅ bzip2/bunzip2"
                else
                    echo "  ❌ bzip2/bunzip2"
                fi
                ;;
            xz)
                if has_command xz; then
                    echo "  ✅ xz/unxz"
                else
                    echo "  ❌ xz/unxz"
                fi
                ;;
            compress)
                if has_command compress; then
                    echo "  ✅ compress/uncompress"
                else
                    echo "  ❌ compress/uncompress"
                fi
                ;;
            zip)
                if has_command zip; then
                    echo "  ✅ zip/unzip"
                else
                    echo "  ❌ zip/unzip"
                fi
                ;;
        esac
    done
}

# Initialize compression system on load
init_compression
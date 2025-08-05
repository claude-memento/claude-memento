#!/usr/bin/env bash

# Common utilities for Claude Memento
# Cross-platform compatible (bash/zsh/dash)
# Support: Windows/macOS/Linux

# Shell compatibility check
check_shell_compatibility() {
    # Check if we're running in a compatible shell
    if [ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ]; then
        # Try to detect other POSIX shells
        if [ -n "$KSH_VERSION" ] || [ -n "$DASH_VERSION" ]; then
            SHELL_TYPE="posix"
        else
            SHELL_TYPE="unknown"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_TYPE="zsh"
        # Enable bash compatibility in zsh
        if command -v setopt >/dev/null 2>&1; then
            setopt BASH_REMATCH 2>/dev/null || true
            setopt KSH_ARRAYS 2>/dev/null || true
        fi
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_TYPE="bash"
    else
        SHELL_TYPE="unknown"
    fi
    
    export SHELL_TYPE
}

# Initialize shell compatibility
check_shell_compatibility

# Detect operating system
detect_os() {
    # Primary detection via $OSTYPE
    case "$OSTYPE" in
        linux*)   echo "linux" ;;
        darwin*)  echo "macos" ;;
        win*)     echo "windows" ;;
        msys*)    echo "windows" ;;
        cygwin*)  echo "windows" ;;
        *)
            # Fallback detection
            if [ -f /proc/version ]; then
                if grep -qi microsoft /proc/version; then
                    echo "wsl"
                else
                    echo "linux"
                fi
            elif command -v sw_vers >/dev/null 2>&1; then
                echo "macos"
            elif [ "$OS" = "Windows_NT" ]; then
                echo "windows"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# Detect shell type for better compatibility
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$KSH_VERSION" ]; then
        echo "ksh"
    elif echo "$0" | grep -q "dash"; then
        echo "dash"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# Get timestamp
get_timestamp() {
    date "+%Y-%m-%d-%H%M%S" 2>/dev/null || date "+%Y-%m-%d-%H%M%S"
}

# Get human-readable time
get_readable_time() {
    date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S"
}

# Calculate time difference
time_diff() {
    local start=$1
    local end=${2:-$(date +%s)}
    local diff=$((end - start))
    
    if [ $diff -lt 60 ]; then
        echo "${diff}초"
    elif [ $diff -lt 3600 ]; then
        echo "$((diff / 60))분"
    elif [ $diff -lt 86400 ]; then
        echo "$((diff / 3600))시간"
    else
        echo "$((diff / 86400))일"
    fi
}

# Get file modification time (cross-platform)
get_file_mtime() {
    local file=$1
    
    case "$OS_TYPE" in
        macos)
            stat -f %m "$file" 2>/dev/null
            ;;
        linux)
            stat -c %Y "$file" 2>/dev/null
            ;;
        windows)
            # For Windows Git Bash/MSYS2
            stat -c %Y "$file" 2>/dev/null || \
            powershell -Command "(Get-Item '$file').LastWriteTime.ToFileTime() / 10000000 - 11644473600" 2>/dev/null
            ;;
        *)
            stat -c %Y "$file" 2>/dev/null
            ;;
    esac
}

# Get file modification time in readable format (cross-platform)
get_file_mtime_readable() {
    local file=$1
    
    case "$OS_TYPE" in
        macos)
            stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null
            ;;
        linux)
            stat -c %y "$file" 2>/dev/null | cut -d. -f1
            ;;
        windows)
            # For Windows Git Bash/MSYS2
            stat -c %y "$file" 2>/dev/null | cut -d. -f1 || \
            powershell -Command "(Get-Item '$file').LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')" 2>/dev/null
            ;;
        *)
            stat -c %y "$file" 2>/dev/null | cut -d. -f1
            ;;
    esac
}

# Check if file is recent (within 5 minutes)
is_recent() {
    local file=$1
    local threshold=${2:-300}  # 5 minutes default
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    local file_time=$(get_file_mtime "$file")
    local current_time=$(date +%s 2>/dev/null || echo $(($(date +%s))))
    local diff=$((current_time - file_time))
    
    [ $diff -lt $threshold ]
}

# Format file size
format_size() {
    local size=$1
    
    if [ $size -lt 1024 ]; then
        echo "${size}B"
    elif [ $size -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    else
        echo "$((size / 1048576))MB"
    fi
}

# Validate JSON
validate_json() {
    local file=$1
    
    if command -v jq &> /dev/null; then
        jq empty "$file" 2>/dev/null
    else
        # Fallback: basic check
        grep -q "^{" "$file" && grep -q "}$" "$file"
    fi
}

# Safe file write with backup
safe_write() {
    local file=$1
    local content=$2
    
    # Create backup if file exists
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
    fi
    
    # Write content
    echo "$content" > "$file"
    
    # Verify write
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        # Restore backup if write failed
        if [ -f "${file}.bak" ]; then
            mv "${file}.bak" "$file"
        fi
        return 1
    fi
    
    # Remove backup on success
    rm -f "${file}.bak"
    return 0
}

# Cross-platform command availability check
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Cross-platform temporary directory
get_temp_dir() {
    if [ -n "$TMPDIR" ]; then
        echo "$TMPDIR"
    elif [ -n "$TMP" ]; then
        echo "$TMP"
    elif [ -n "$TEMP" ]; then
        echo "$TEMP"
    elif [ -d "/tmp" ]; then
        echo "/tmp"
    else
        echo "."
    fi
}

# Cross-platform temporary file creation
create_temp_file() {
    local prefix="${1:-memento}"
    local temp_dir=$(get_temp_dir)
    
    if has_command mktemp; then
        mktemp "$temp_dir/${prefix}.XXXXXX"
    else
        # Fallback for systems without mktemp
        local temp_file="$temp_dir/${prefix}.$$.$RANDOM"
        touch "$temp_file"
        echo "$temp_file"
    fi
}

# Cross-platform file locking
lock_file() {
    local file="$1"
    local lock_file="${file}.lock"
    local timeout="${2:-10}"
    local count=0
    
    while [ $count -lt $timeout ]; do
        if (set -C; echo $$ > "$lock_file") 2>/dev/null; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    return 1
}

unlock_file() {
    local file="$1"
    local lock_file="${file}.lock"
    rm -f "$lock_file"
}

# Cross-platform process checking
is_process_running() {
    local pid="$1"
    
    case "$OS_TYPE" in
        macos|linux|wsl)
            kill -0 "$pid" 2>/dev/null
            ;;
        windows)
            tasklist /FI "PID eq $pid" 2>/dev/null | grep -q "$pid"
            ;;
        *)
            kill -0 "$pid" 2>/dev/null
            ;;
    esac
}

# Cross-platform file size
get_file_size() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo 0
        return 1
    fi
    
    case "$OS_TYPE" in
        macos)
            stat -f%z "$file" 2>/dev/null || echo 0
            ;;
        linux|wsl)
            stat -c%s "$file" 2>/dev/null || echo 0
            ;;
        windows)
            if has_command stat; then
                stat -c%s "$file" 2>/dev/null || echo 0
            else
                # PowerShell fallback
                powershell -Command "(Get-Item '$file').Length" 2>/dev/null || echo 0
            fi
            ;;
        *)
            # POSIX fallback using ls
            ls -l "$file" 2>/dev/null | awk '{print $5}' || echo 0
            ;;
    esac
}

# Cross-platform directory size
get_dir_size() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo 0
        return 1
    fi
    
    case "$OS_TYPE" in
        macos)
            du -sk "$dir" 2>/dev/null | cut -f1 || echo 0
            ;;
        linux|wsl)
            du -sk "$dir" 2>/dev/null | cut -f1 || echo 0
            ;;
        windows)
            if has_command du; then
                du -sk "$dir" 2>/dev/null | cut -f1 || echo 0
            else
                # PowerShell fallback
                powershell -Command "(Get-ChildItem '$dir' -Recurse | Measure-Object -Property Length -Sum).Sum / 1024" 2>/dev/null || echo 0
            fi
            ;;
        *)
            du -sk "$dir" 2>/dev/null | cut -f1 || echo 0
            ;;
    esac
}

# Cross-platform path normalization
normalize_path() {
    local path="$1"
    
    # Convert Windows paths to Unix-style for Git Bash/WSL
    if [ "$OS_TYPE" = "windows" ]; then
        echo "$path" | sed 's|\\|/|g'
    else
        echo "$path"
    fi
}

# Cross-platform home directory
get_home_dir() {
    if [ -n "$HOME" ]; then
        echo "$HOME"
    elif [ -n "$USERPROFILE" ]; then
        normalize_path "$USERPROFILE"
    else
        echo "."
    fi
}

# Cross-platform user name
get_username() {
    if [ -n "$USER" ]; then
        echo "$USER"
    elif [ -n "$USERNAME" ]; then
        echo "$USERNAME"
    elif has_command whoami; then
        whoami
    else
        echo "unknown"
    fi
}

# Cross-platform hostname
get_hostname() {
    if [ -n "$HOSTNAME" ]; then
        echo "$HOSTNAME"
    elif [ -n "$COMPUTERNAME" ]; then
        echo "$COMPUTERNAME"
    elif has_command hostname; then
        hostname
    else
        echo "unknown"
    fi
}

# Array compatibility (bash vs zsh)
array_length() {
    local array_name="$1"
    
    case "$SHELL_TYPE" in
        zsh)
            eval "echo \${#${array_name}[@]}"
            ;;
        bash|posix|*)
            eval "echo \${#${array_name}[@]}"
            ;;
    esac
}

# String manipulation compatibility
string_contains() {
    local string="$1"
    local substring="$2"
    
    case "$string" in
        *"$substring"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Cross-platform terminal width
get_terminal_width() {
    if has_command tput; then
        tput cols 2>/dev/null || echo 80
    elif [ -n "$COLUMNS" ]; then
        echo "$COLUMNS"
    else
        echo 80
    fi
}

# Cross-platform color support detection
supports_color() {
    local term="$TERM"
    
    # Check if output is a terminal
    if [ ! -t 1 ]; then
        return 1
    fi
    
    # Check TERM variable
    case "$term" in
        *color*|xterm*|screen*|tmux*|rxvt*)
            return 0
            ;;
        *)
            # Check if tput is available and supports colors
            if has_command tput && tput colors >/dev/null 2>&1; then
                local colors=$(tput colors 2>/dev/null || echo 0)
                [ "$colors" -ge 8 ]
            else
                return 1
            fi
            ;;
    esac
}

# Setup colors based on support
setup_colors() {
    if supports_color; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        PURPLE=''
        CYAN=''
        WHITE=''
        BOLD=''
        NC=''
    fi
    
    export RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD NC
}

# Initialize colors
setup_colors

# Cross-platform notification
show_notification() {
    local title="$1"
    local message="$2"
    
    case "$OS_TYPE" in
        macos)
            if has_command osascript; then
                osascript -e "display notification \"$message\" with title \"$title\""
            else
                echo "[$title] $message"
            fi
            ;;
        linux|wsl)
            if has_command notify-send; then
                notify-send "$title" "$message"
            elif has_command zenity; then
                zenity --info --title="$title" --text="$message" &
            else
                echo "[$title] $message"
            fi
            ;;
        windows)
            if has_command powershell; then
                powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('$message', '$title')"
            else
                echo "[$title] $message"
            fi
            ;;
        *)
            echo "[$title] $message"
            ;;
    esac
}
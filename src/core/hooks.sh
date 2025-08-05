#!/usr/bin/env bash

# Claude Memento Hook System
# Cross-platform compatible (Windows/macOS/Linux, bash/zsh)

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

# Hook system configuration
HOOKS_DIR="${MEMENTO_DIR}/hooks"
HOOK_TIMEOUT="${MEMENTO_HOOK_TIMEOUT:-30}"
HOOK_LOG_FILE="${MEMENTO_DIR}/logs/hooks.log"

# Available hook events
HOOK_EVENTS=(
    "pre-checkpoint" "post-checkpoint"
    "pre-load" "post-load" 
    "pre-cleanup" "post-cleanup"
    "pre-config" "post-config"
    "pre-list" "post-list"
)

# Initialize hook system
init_hooks() {
    log_info "Initializing hook system..."
    
    # Create hook directories
    for phase in pre post; do
        local hook_dir="$HOOKS_DIR/$phase"
        if [ ! -d "$hook_dir" ]; then
            mkdir -p "$hook_dir"
            log_debug "Created hook directory: $hook_dir"
        fi
    done
    
    # Create hook documentation
    create_hook_documentation
    
    # Create sample hooks
    create_sample_hooks
    
    # Setup hook log
    mkdir -p "$(dirname "$HOOK_LOG_FILE")"
    touch "$HOOK_LOG_FILE"
    
    log_success "Hook system initialized successfully"
}

# Create hook documentation
create_hook_documentation() {
    local readme_file="$HOOKS_DIR/README.md"
    
    cat > "$readme_file" << 'EOF'
# Claude Memento Hooks

## 개요
훅은 Claude Memento의 특정 이벤트 발생 시 자동으로 실행되는 스크립트입니다.

## 지원되는 이벤트
- `pre-checkpoint` / `post-checkpoint`: 체크포인트 생성 전/후
- `pre-load` / `post-load`: 컨텍스트 로드 전/후  
- `pre-cleanup` / `post-cleanup`: 정리 작업 전/후
- `pre-config` / `post-config`: 설정 변경 전/후
- `pre-list` / `post-list`: 목록 조회 전/후

## 훅 작성 방법

### 1. 디렉토리 구조
```
hooks/
├── pre/          # 이벤트 실행 전 훅들
│   ├── backup.sh
│   └── validate.sh
└── post/         # 이벤트 실행 후 훅들
    ├── notify.sh
    └── cleanup.sh
```

### 2. 훅 스크립트 예시

#### Bash/Shell 훅
```bash
#!/usr/bin/env bash
# hooks/post/notify.sh

# 환경 변수를 통해 이벤트 정보 접근
echo "Event: $HOOK_EVENT"
echo "Phase: $HOOK_PHASE" 
echo "Context: $HOOK_CONTEXT"

# 체크포인트 생성 시 알림
if [ "$HOOK_EVENT" = "checkpoint" ]; then
    case "$OS_TYPE" in
        macos)
            osascript -e "display notification \"체크포인트 저장됨\" with title \"Claude Memento\""
            ;;
        linux|wsl)
            notify-send "Claude Memento" "체크포인트 저장됨"
            ;;
        windows)
            # Windows 알림 (PowerShell)
            powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('체크포인트 저장됨', 'Claude Memento')"
            ;;
    esac
fi
```

#### Python 훅
```python
#!/usr/bin/env python3
# hooks/post/backup.py

import os
import shutil
from datetime import datetime

# 환경 변수에서 정보 가져오기
event = os.environ.get('HOOK_EVENT', '')
memento_dir = os.environ.get('MEMENTO_DIR', '')

if event == 'checkpoint' and memento_dir:
    # 백업 디렉토리 생성
    backup_dir = os.path.join(memento_dir, 'backup')
    os.makedirs(backup_dir, exist_ok=True)
    
    # 최신 체크포인트 백업
    checkpoints_dir = os.path.join(memento_dir, 'checkpoints')
    if os.path.exists(checkpoints_dir):
        files = [f for f in os.listdir(checkpoints_dir) if f.endswith('.md')]
        if files:
            latest = max(files, key=lambda x: os.path.getmtime(
                os.path.join(checkpoints_dir, x)))
            src = os.path.join(checkpoints_dir, latest)
            dst = os.path.join(backup_dir, f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{latest}")
            shutil.copy2(src, dst)
            print(f"백업 완료: {latest}")
```

### 3. 환경 변수

훅 실행 시 다음 환경 변수들이 설정됩니다:

- `HOOK_EVENT`: 이벤트 타입 (checkpoint, load, cleanup, config, list)
- `HOOK_PHASE`: 훅 단계 (pre, post)
- `HOOK_CONTEXT`: 이벤트 관련 추가 정보 (JSON 형태)
- `MEMENTO_DIR`: Claude Memento 설치 디렉토리
- `OS_TYPE`: 운영체제 타입 (macos, linux, windows, wsl)
- `SHELL_TYPE`: 셸 타입 (bash, zsh, etc)

### 4. 설치 방법

1. `hooks/pre/` 또는 `hooks/post/` 디렉토리에 스크립트 파일 생성
2. 실행 권한 부여:
   ```bash
   chmod +x hooks/post/your-hook.sh
   ```
3. 테스트:
   ```bash
   /cm:test-hooks
   ```

### 5. 크로스플랫폼 호환성

훅 스크립트는 다음 환경에서 실행 가능합니다:
- **macOS**: bash, zsh
- **Linux**: bash, zsh, dash
- **Windows**: Git Bash, WSL, MSYS2
- **언어**: Bash, Python, Node.js, PowerShell 등

### 6. 모범 사례

#### DO
- ✅ 빠른 실행 (30초 이내)
- ✅ 오류 처리 구현
- ✅ 로그 출력
- ✅ 크로스플랫폼 호환성 고려

#### DON'T  
- ❌ 긴 시간이 걸리는 작업
- ❌ 사용자 입력 요구
- ❌ 시스템 중요 파일 수정
- ❌ 네트워크 의존적 작업 (옵션 없이)

### 7. 문제 해결

훅 실행 로그는 `logs/hooks.log`에서 확인할 수 있습니다.

```bash
tail -f ~/.claude/memento/logs/hooks.log
```
EOF

    log_debug "Created hook documentation"
}

# Create sample hooks
create_sample_hooks() {
    # Sample notification hook
    cat > "$HOOKS_DIR/post/notify.sh" << 'EOF'
#!/usr/bin/env bash

# Load common utilities for cross-platform support
if [ -f "$MEMENTO_DIR/src/utils/common.sh" ]; then
    source "$MEMENTO_DIR/src/utils/common.sh"
fi

# Cross-platform notification
if [ "$HOOK_EVENT" = "checkpoint" ]; then
    show_notification "Claude Memento" "체크포인트가 저장되었습니다"
fi
EOF

    # Sample backup hook  
    cat > "$HOOKS_DIR/pre/backup.sh" << 'EOF'
#!/usr/bin/env bash

# Load common utilities
if [ -f "$MEMENTO_DIR/src/utils/common.sh" ]; then
    source "$MEMENTO_DIR/src/utils/common.sh"
fi

# Backup important checkpoints before cleanup
if [ "$HOOK_EVENT" = "cleanup" ]; then
    local backup_dir="$MEMENTO_DIR/backup"
    mkdir -p "$backup_dir"
    
    # Find recent checkpoints (last 7 days)
    find "$MEMENTO_DIR/checkpoints" -name "*.md" -mtime -7 | while read -r file; do
        if [ -f "$file" ]; then
            cp "$file" "$backup_dir/"
        fi
    done
    
    echo "백업 완료: $(ls "$backup_dir" | wc -l)개 파일"
fi
EOF

    # Set execute permissions
    if [ "$OS_TYPE" != "windows" ]; then
        chmod +x "$HOOKS_DIR/post/notify.sh"
        chmod +x "$HOOKS_DIR/pre/backup.sh"
    fi
    
    log_debug "Created sample hooks"
}

# Run hooks for specific event and phase
run_hooks() {
    local phase="$1"    # pre or post
    local event="$2"    # checkpoint, load, cleanup, etc
    local context="$3"  # additional context (optional)
    
    local hook_dir="$HOOKS_DIR/$phase"
    local executed_count=0
    local failed_count=0
    
    # Check if hooks directory exists
    if [ ! -d "$hook_dir" ]; then
        log_debug "Hook directory not found: $hook_dir"
        return 0
    fi
    
    # Set hook environment variables
    export HOOK_EVENT="$event"
    export HOOK_PHASE="$phase"
    export HOOK_CONTEXT="$context"
    export MEMENTO_DIR="$MEMENTO_DIR"
    export OS_TYPE="$OS_TYPE"
    export SHELL_TYPE="$SHELL_TYPE"
    
    log_debug "Running $phase-$event hooks..."
    
    # Find and execute hooks
    for hook_file in "$hook_dir"/*; do
        # Skip if not a file or if it's the README
        if [ ! -f "$hook_file" ] || [ "$(basename "$hook_file")" = "README.md" ]; then
            continue
        fi
        
        local hook_name=$(basename "$hook_file")
        
        # Check if file is executable
        if [ "$OS_TYPE" = "windows" ] || [ -x "$hook_file" ]; then
            log_debug "Executing hook: $hook_name"
            
            if execute_hook "$hook_file" "$hook_name"; then
                executed_count=$((executed_count + 1))
                log_hook "SUCCESS" "$phase-$event" "$hook_name" "Hook executed successfully"
            else
                failed_count=$((failed_count + 1))
                log_hook "FAILED" "$phase-$event" "$hook_name" "Hook execution failed"
            fi
        else
            log_debug "Skipping non-executable hook: $hook_name"
        fi
    done
    
    # Summary
    if [ $executed_count -gt 0 ] || [ $failed_count -gt 0 ]; then
        log_info "Hooks executed: $executed_count, failed: $failed_count"
    fi
    
    # Cleanup environment
    unset HOOK_EVENT HOOK_PHASE HOOK_CONTEXT
    
    return $failed_count
}

# Execute individual hook with timeout
execute_hook() {
    local hook_file="$1"
    local hook_name="$2"
    local start_time=$(date +%s)
    
    # Determine how to execute the hook
    local executor=""
    case "$hook_file" in
        *.py)
            if has_command python3; then
                executor="python3"
            elif has_command python; then
                executor="python"
            fi
            ;;
        *.js)
            if has_command node; then
                executor="node"
            fi
            ;;
        *.ps1)
            if has_command powershell; then
                executor="powershell -File"
            fi
            ;;
        *)
            # Shell script or executable
            case "$SHELL_TYPE" in
                zsh)
                    executor="zsh"
                    ;;
                bash|*)
                    executor="bash"
                    ;;
            esac
            ;;
    esac
    
    # Execute with timeout
    local success=false
    local output=""
    local temp_output=$(create_temp_file "hook_output")
    
    # Use timeout if available
    if has_command timeout; then
        if [ -n "$executor" ]; then
            timeout "$HOOK_TIMEOUT" $executor "$hook_file" > "$temp_output" 2>&1
        else
            timeout "$HOOK_TIMEOUT" "$hook_file" > "$temp_output" 2>&1
        fi
        local exit_code=$?
    else
        # Fallback without timeout
        if [ -n "$executor" ]; then
            $executor "$hook_file" > "$temp_output" 2>&1
        else
            "$hook_file" > "$temp_output" 2>&1
        fi
        local exit_code=$?
    fi
    
    # Read output
    if [ -f "$temp_output" ]; then
        output=$(cat "$temp_output")
        rm -f "$temp_output"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Check result
    if [ $exit_code -eq 0 ]; then
        success=true
        if [ -n "$output" ]; then
            log_debug "Hook output ($hook_name): $output"
        fi
    else
        log_error "Hook failed ($hook_name): $output"
    fi
    
    # Log execution details
    log_hook_details "$hook_name" "$exit_code" "$duration" "$output"
    
    $success
}

# Log hook execution details
log_hook_details() {
    local hook_name="$1"
    local exit_code="$2"
    local duration="$3"
    local output="$4"
    
    local timestamp=$(get_readable_time)
    local status="SUCCESS"
    
    if [ $exit_code -ne 0 ]; then
        status="FAILED"
    fi
    
    # Write to hook log file
    {
        echo "[$timestamp] $status: $hook_name (exit: $exit_code, duration: ${duration}s)"
        if [ -n "$output" ]; then
            echo "  Output: $output"
        fi
        echo "  Event: $HOOK_EVENT, Phase: $HOOK_PHASE"
        echo "  Context: $HOOK_CONTEXT"
        echo "---"
    } >> "$HOOK_LOG_FILE"
}

# Simple hook logging
log_hook() {
    local status="$1"
    local event="$2" 
    local hook="$3"
    local message="$4"
    
    local timestamp=$(get_readable_time)
    echo "[$timestamp] $status: $event/$hook - $message" >> "$HOOK_LOG_FILE"
}

# List available hooks
list_hooks() {
    echo "${BLUE}📋 Available Hooks${NC}"
    echo "=================="
    
    for phase in pre post; do
        local hook_dir="$HOOKS_DIR/$phase"
        echo -e "\n${YELLOW}$phase hooks:${NC}"
        
        if [ -d "$hook_dir" ]; then
            local count=0
            for hook_file in "$hook_dir"/*; do
                if [ -f "$hook_file" ] && [ "$(basename "$hook_file")" != "README.md" ]; then
                    local hook_name=$(basename "$hook_file")
                    local size=$(get_file_size "$hook_file")
                    local mtime=$(get_file_mtime_readable "$hook_file")
                    local executable="❌"
                    
                    if [ "$OS_TYPE" = "windows" ] || [ -x "$hook_file" ]; then
                        executable="✅"
                    fi
                    
                    echo "  $executable $hook_name ($(format_size $size), $mtime)"
                    count=$((count + 1))
                fi
            done
            
            if [ $count -eq 0 ]; then
                echo "  (no hooks)"
            fi
        else
            echo "  (directory not found)"
        fi
    done
    
    echo -e "\n${CYAN}Hook log: $HOOK_LOG_FILE${NC}"
}

# Test hook system
test_hooks() {
    echo "${BLUE}🧪 Testing Hook System${NC}"
    echo "====================="
    
    local test_context='{"test": true, "checkpoint": "test-checkpoint.md"}'
    
    echo -e "\n${YELLOW}Testing pre-checkpoint hooks...${NC}"
    run_hooks "pre" "checkpoint" "$test_context"
    
    echo -e "\n${YELLOW}Testing post-checkpoint hooks...${NC}" 
    run_hooks "post" "checkpoint" "$test_context"
    
    echo -e "\n${GREEN}Hook system test completed${NC}"
    echo "Check $HOOK_LOG_FILE for detailed logs"
}

# Show hook logs
show_hook_logs() {
    local lines="${1:-20}"
    
    if [ -f "$HOOK_LOG_FILE" ]; then
        echo "${BLUE}📄 Hook Logs (last $lines lines)${NC}"
        echo "=========================="
        tail -n "$lines" "$HOOK_LOG_FILE"
    else
        echo "${YELLOW}No hook logs found${NC}"
    fi
}

# Clean hook logs  
clean_hook_logs() {
    local days="${1:-30}"
    
    if [ -f "$HOOK_LOG_FILE" ]; then
        # Keep only recent logs
        local temp_log=$(create_temp_file "hook_log")
        local cutoff_date=$(date -d "$days days ago" +%Y-%m-%d 2>/dev/null || date -v-${days}d +%Y-%m-%d 2>/dev/null)
        
        if [ -n "$cutoff_date" ]; then
            grep "$cutoff_date\|$(date +%Y-%m-%d)" "$HOOK_LOG_FILE" > "$temp_log" 2>/dev/null || true
            if [ -s "$temp_log" ]; then
                mv "$temp_log" "$HOOK_LOG_FILE"
                echo "Hook logs cleaned (kept last $days days)"
            fi
        fi
        
        rm -f "$temp_log"
    fi
}

# Hook system status
hook_status() {
    echo "${BLUE}🎣 Hook System Status${NC}"
    echo "===================="
    
    # Check if hooks directory exists
    if [ -d "$HOOKS_DIR" ]; then
        echo "${GREEN}✅ Hooks directory: $HOOKS_DIR${NC}"
    else
        echo "${RED}❌ Hooks directory not found${NC}"
        return 1
    fi
    
    # Count hooks
    local pre_count=0
    local post_count=0
    
    if [ -d "$HOOKS_DIR/pre" ]; then
        pre_count=$(find "$HOOKS_DIR/pre" -type f ! -name "README.md" | wc -l)
    fi
    
    if [ -d "$HOOKS_DIR/post" ]; then
        post_count=$(find "$HOOKS_DIR/post" -type f ! -name "README.md" | wc -l)
    fi
    
    echo "Pre-hooks: $pre_count"
    echo "Post-hooks: $post_count"
    
    # Check log file
    if [ -f "$HOOK_LOG_FILE" ]; then
        local log_size=$(get_file_size "$HOOK_LOG_FILE")
        echo "Log file: $(format_size $log_size)"
    else
        echo "Log file: not created"
    fi
    
    # Recent activity
    if [ -f "$HOOK_LOG_FILE" ]; then
        local last_execution=$(tail -n 1 "$HOOK_LOG_FILE" 2>/dev/null | grep -o '^\[[^]]*\]' | tr -d '[]' || echo "Never")
        echo "Last execution: $last_execution"
    fi
    
    echo -e "\n${CYAN}Supported events:${NC}"
    for event in "${HOOK_EVENTS[@]}"; do
        echo "  - $event"
    done
}

# Main function for CLI usage
main() {
    local command="$1"
    shift
    
    case "$command" in
        init)
            init_hooks
            ;;
        list)
            list_hooks
            ;;
        test)
            test_hooks
            ;;
        status)
            hook_status
            ;;
        logs)
            show_hook_logs "$@"
            ;;
        clean-logs)
            clean_hook_logs "$@"
            ;;
        run)
            local phase="$1"
            local event="$2"
            local context="$3"
            run_hooks "$phase" "$event" "$context"
            ;;
        *)
            echo "Usage: $0 {init|list|test|status|logs|clean-logs|run}"
            echo ""
            echo "Commands:"
            echo "  init        - Initialize hook system"
            echo "  list        - List available hooks"
            echo "  test        - Test hook system"
            echo "  status      - Show hook system status"
            echo "  logs [n]    - Show last n lines of hook logs"
            echo "  clean-logs [days] - Clean old hook logs"
            echo "  run <phase> <event> [context] - Run hooks"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ "${ZSH_EVAL_CONTEXT}" = "toplevel" ]; then
    main "$@"
fi
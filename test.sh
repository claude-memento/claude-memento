#!/bin/bash

# Claude Memento Test Script
# Cross-platform compatibility test

set -e

# Detect OS
detect_os() {
    case "$OSTYPE" in
        linux*)   echo "linux" ;;
        darwin*)  echo "macos" ;;
        win*)     echo "windows" ;;
        msys*)    echo "windows" ;;
        cygwin*)  echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

OS_TYPE=$(detect_os)

# Colors (cross-platform)
if [[ "$OS_TYPE" == "windows" ]]; then
    GREEN=''
    RED=''
    YELLOW=''
    NC=''
else
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

# Test directory (cross-platform)
if [[ "$OS_TYPE" == "windows" ]]; then
    TEST_DIR="$TEMP/claude-memento-test"
else
    TEST_DIR="/tmp/claude-memento-test"
fi
MEMENTO_DIR="$TEST_DIR/.claude/memento"

echo "🧪 Claude Memento Test Suite"
echo "============================"

# Setup test environment
setup_test() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    export HOME="$TEST_DIR"
    export CLAUDE_MEMENTO_DIR="$MEMENTO_DIR"
    
    # Simulate installation
    mkdir -p "$MEMENTO_DIR"/{checkpoints,config,logs,commands,core,utils}
    cp -r src/* "$MEMENTO_DIR/"
    
    # Create config
    mkdir -p "$MEMENTO_DIR/config"
    cp config/default.json "$MEMENTO_DIR/config/" 2>/dev/null || \
    cat > "$MEMENTO_DIR/config/default.json" << 'EOF'
{
  "checkpoint": {
    "retention": 3,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  }
}
EOF
    
    echo -e "${GREEN}✓ Test environment ready${NC}"
}

# Test function
run_test() {
    local test_name=$1
    local test_cmd=$2
    
    echo -n "Testing $test_name... "
    
    if eval "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

# Cleanup
cleanup() {
    rm -rf "$TEST_DIR"
}

# Tests
test_save_checkpoint() {
    "$MEMENTO_DIR/commands/save.sh" "Test checkpoint"
    [ -f "$MEMENTO_DIR/checkpoints"/checkpoint-*.md ]
}

test_load_context() {
    "$MEMENTO_DIR/commands/save.sh" "Test for load"
    "$MEMENTO_DIR/commands/load.sh" > /dev/null
}

test_status_command() {
    "$MEMENTO_DIR/commands/status.sh" > /dev/null
}

test_list_checkpoints() {
    "$MEMENTO_DIR/commands/save.sh" "Test 1"
    "$MEMENTO_DIR/commands/save.sh" "Test 2"
    "$MEMENTO_DIR/commands/list.sh" > /dev/null
}

test_config_show() {
    "$MEMENTO_DIR/commands/config.sh" show > /dev/null
}

test_memory_init() {
    source "$MEMENTO_DIR/core/memory.sh"
    init_memory
    [ -f "$MEMENTO_DIR/claude-memory.md" ] && [ -f "$MEMENTO_DIR/claude-context.md" ]
}

test_checkpoint_cleanup() {
    # Create 5 checkpoints
    for i in {1..5}; do
        "$MEMENTO_DIR/commands/save.sh" "Test $i"
        sleep 1
    done
    
    # Check that only 3 remain (retention setting)
    local count=$(ls "$MEMENTO_DIR/checkpoints"/checkpoint-*.md 2>/dev/null | wc -l)
    [ "$count" -eq 3 ]
}

# Run tests
setup_test

echo
echo "Running tests..."
echo "----------------"

FAILED=0

run_test "save checkpoint" test_save_checkpoint || ((FAILED++))
run_test "load context" test_load_context || ((FAILED++))
run_test "status command" test_status_command || ((FAILED++))
run_test "list checkpoints" test_list_checkpoints || ((FAILED++))
run_test "config show" test_config_show || ((FAILED++))
run_test "memory initialization" test_memory_init || ((FAILED++))
run_test "checkpoint cleanup" test_checkpoint_cleanup || ((FAILED++))

echo
echo "----------------"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ $FAILED tests failed${NC}"
fi

# Cleanup
cleanup

exit $FAILED
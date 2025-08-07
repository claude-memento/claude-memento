#!/bin/bash

# Claude Memento - Chunk System Integration Test
# Tests the complete chunk workflow: create, relate, search, load

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMENTO_DIR="$HOME/.claude/memento"

# Test data
TEST_CHECKPOINT="test-checkpoint-$(date +%Y%m%d-%H%M%S)"
TEST_CONTENT="# Test Checkpoint

This is a test checkpoint for the chunk system.
It contains multiple paragraphs to test chunking.

## Section 1: API Implementation

The API implementation includes several endpoints:
- GET /users - List all users
- POST /users - Create a new user
- GET /users/:id - Get user by ID
- PUT /users/:id - Update user
- DELETE /users/:id - Delete user

The implementation uses Express.js and MongoDB.

## Section 2: Database Schema

The database schema includes:
- User collection with fields: name, email, created_at
- Posts collection with fields: title, content, author, published
- Comments collection with fields: text, post_id, user_id

## Section 3: Authentication

Authentication is handled using JWT tokens.
The token includes user ID and expiration time.
Refresh tokens are stored in Redis.

## Section 4: Performance Optimization

Performance optimizations include:
- Database indexing on frequently queried fields
- Caching with Redis for hot data
- Query optimization using aggregation pipelines
- Connection pooling for database connections

## Section 5: Testing

Testing strategy includes:
- Unit tests for individual functions
- Integration tests for API endpoints
- End-to-end tests for user workflows
- Performance tests for load testing
"

echo -e "${BLUE}🧪 Claude Memento Chunk System Test${NC}"
echo "======================================"

# Function to run test with status
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -ne "${YELLOW}Testing: $test_name...${NC} "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        return 1
    fi
}

# Prerequisites check
echo -e "${YELLOW}Checking prerequisites...${NC}"
check_command "node" || exit 1
check_command "jq" || { echo "Installing jq..."; brew install jq 2>/dev/null || sudo apt-get install -y jq 2>/dev/null || true; }

# Test 1: Create test checkpoint
echo -e "\n${BLUE}Test 1: Checkpoint Creation${NC}"

# Create checkpoint file
CHECKPOINT_FILE="$MEMENTO_DIR/checkpoints/$TEST_CHECKPOINT.md"
mkdir -p "$MEMENTO_DIR/checkpoints"
echo "$TEST_CONTENT" > "$CHECKPOINT_FILE"

run_test "Checkpoint created" "[ -f '$CHECKPOINT_FILE' ]"

# Test 2: Chunk the checkpoint
echo -e "\n${BLUE}Test 2: Chunking${NC}"

cd "$MEMENTO_DIR/src/chunk" || exit 1

# Run chunker
CHUNK_OUTPUT=$(node checkpoint-chunker.js "$TEST_CHECKPOINT" 2>&1)
run_test "Chunking completed" "echo '$CHUNK_OUTPUT' | grep -q 'chunks created'"

# Count chunks created
CHUNK_COUNT=$(ls "$MEMENTO_DIR/chunks" 2>/dev/null | grep "^chunk-" | wc -l)
echo "  Chunks created: $CHUNK_COUNT"

# Test 3: Build graph relationships
echo -e "\n${BLUE}Test 3: Graph Building${NC}"

# Initialize graph
run_test "Graph initialization" "node graph.js stats"

# Build semantic relations
run_test "Semantic relations" "node graph.js build-semantic 0.2"

# Get graph stats
GRAPH_STATS=$(node graph.js stats 2>/dev/null)
if [ -n "$GRAPH_STATS" ]; then
    echo "  Graph stats:"
    echo "$GRAPH_STATS" | jq -r '.nodeCount' | xargs echo "    - Nodes:"
    echo "$GRAPH_STATS" | jq -r '.edgeCount' | xargs echo "    - Edges:"
fi

# Test 4: Vectorization
echo -e "\n${BLUE}Test 4: Vectorization${NC}"

# Build vectors
run_test "Vector building" "node vectorizer.js build"

# Get vectorizer stats
VECTOR_STATS=$(node vectorizer.js stats 2>/dev/null)
if [ -n "$VECTOR_STATS" ]; then
    echo "  Vector stats:"
    echo "$VECTOR_STATS" | jq -r '.documents' | xargs echo "    - Documents:"
    echo "$VECTOR_STATS" | jq -r '.terms' | xargs echo "    - Terms:"
fi

# Test 5: Smart Loading - Query Tests
echo -e "\n${BLUE}Test 5: Smart Loading${NC}"

# Test queries
QUERIES=(
    "API implementation"
    "database schema"
    "authentication JWT"
    "performance optimization"
    "testing strategy"
)

for query in "${QUERIES[@]}"; do
    RESULT=$(node smart-loader.js query "$query" 2>/dev/null | head -20)
    if [ -n "$RESULT" ]; then
        echo -e "  ${GREEN}✓${NC} Query: \"$query\" - Found results"
    else
        echo -e "  ${RED}✗${NC} Query: \"$query\" - No results"
    fi
done

# Test 6: Graph traversal
echo -e "\n${BLUE}Test 6: Graph Traversal${NC}"

# Get first chunk ID
FIRST_CHUNK=$(ls "$MEMENTO_DIR/chunks" 2>/dev/null | grep "^chunk-" | head -1 | sed 's/.md$//')

if [ -n "$FIRST_CHUNK" ]; then
    RELATED=$(node graph.js find "$FIRST_CHUNK" 2 2>/dev/null)
    RELATED_COUNT=$(echo "$RELATED" | jq '. | length' 2>/dev/null || echo "0")
    echo "  Found $RELATED_COUNT related chunks for $FIRST_CHUNK"
fi

# Test 7: Keyword search
echo -e "\n${BLUE}Test 7: Keyword Search${NC}"

KEYWORDS=("API" "database" "authentication" "performance" "testing")

for keyword in "${KEYWORDS[@]}"; do
    RESULTS=$(node graph.js keyword "$keyword" 2>/dev/null)
    COUNT=$(echo "$RESULTS" | jq '. | length' 2>/dev/null || echo "0")
    echo "  Keyword \"$keyword\": $COUNT chunks"
done

# Test 8: Load checkpoint with query
echo -e "\n${BLUE}Test 8: Checkpoint Query Loading${NC}"

# Test loading with query filter
FILTERED=$(cd "$MEMENTO_DIR/src/commands" && bash load.sh "$TEST_CHECKPOINT" --query "API" 2>/dev/null)
if [ -n "$FILTERED" ]; then
    echo -e "  ${GREEN}✓${NC} Loaded checkpoint with query filter"
else
    echo -e "  ${YELLOW}⚠${NC} Query filter returned no results"
fi

# Test 9: Performance benchmark
echo -e "\n${BLUE}Test 9: Performance Benchmark${NC}"

# Measure search time
START_TIME=$(date +%s%N)
node smart-loader.js query "database optimization" 2>/dev/null > /dev/null
END_TIME=$(date +%s%N)
ELAPSED=$((($END_TIME - $START_TIME) / 1000000))
echo "  Search time: ${ELAPSED}ms"

if [ $ELAPSED -lt 100 ]; then
    echo -e "  ${GREEN}✓${NC} Performance: Excellent (<100ms)"
elif [ $ELAPSED -lt 500 ]; then
    echo -e "  ${YELLOW}⚠${NC} Performance: Good (<500ms)"
else
    echo -e "  ${RED}✗${NC} Performance: Needs optimization (${ELAPSED}ms)"
fi

# Test 10: Cleanup test data
echo -e "\n${BLUE}Test 10: Cleanup${NC}"

# Remove test checkpoint
rm -f "$CHECKPOINT_FILE"
run_test "Checkpoint removed" "[ ! -f '$CHECKPOINT_FILE' ]"

# Remove test chunks (optional - keep for debugging)
# find "$MEMENTO_DIR/chunks" -name "chunk-*" -mtime -1 -delete

echo -e "\n${GREEN}✅ Chunk System Test Complete!${NC}"

# Summary
echo -e "\n${BLUE}Summary:${NC}"
echo "  - Chunks created: $CHUNK_COUNT"
echo "  - Graph nodes: $(echo "$GRAPH_STATS" | jq -r '.nodeCount' 2>/dev/null || echo "0")"
echo "  - Graph edges: $(echo "$GRAPH_STATS" | jq -r '.edgeCount' 2>/dev/null || echo "0")"
echo "  - Search performance: ${ELAPSED}ms"

# Return success
exit 0
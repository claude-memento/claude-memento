# Claude Memento - Claude Code Integration Plan

## Phase 1: Immediate Impact (Day 1)
**목표**: Claude Code가 Memento 인식하도록 설정

### 1.1 CLAUDE.md 업데이트 (30분)
```markdown
<!-- ~/.claude/CLAUDE.md에 추가 -->
## Claude Memento Commands
- `/cm:save [reason]` - 현재 컨텍스트 저장
- `/cm:load [checkpoint]` - 이전 컨텍스트 복원
- `/cm:chunk search [query]` - 지능형 검색
- `/cm:status` - 메모리 상태 확인

## Auto-Context Tracking
파일: ~/.claude/memento/claude-memento.md
- 모든 대화 자동 기록
- 파일 작업 추적
- 결정 사항 보존
```

### 1.2 claude-memento.md 생성 (1시간)
```javascript
// 실시간 컨텍스트 추적 파일
{
  "session": {
    "id": "2025-08-07-0856",
    "started": "2025-08-07T08:56:00",
    "context": []
  },
  "files": {
    "opened": [],
    "modified": [],
    "created": []
  },
  "decisions": [],
  "tasks": []
}
```

## Phase 2: Chunk System Activation (Day 2)
**목표**: 자동 청킹 및 저장

### 2.1 Auto-Chunking 구현
```javascript
// save.sh 수정
if [ $(estimateTokens "$content") -gt 3000 ]; then
  node "$MEMENTO_DIR/src/chunk/chunker.js" "$content"
fi
```

### 2.2 청크 메타데이터
```json
{
  "id": "chunk-xxx",
  "position": 1,
  "tokens": 2500,
  "keywords": ["API", "implementation"],
  "timestamp": "2025-08-07T09:00:00",
  "relations": {
    "next": "chunk-yyy",
    "previous": null,
    "semantic": ["chunk-zzz"]
  }
}
```

## Phase 3: Graph System (Day 3)
**목표**: 관계 기반 검색

### 3.1 Graph 구조
```javascript
class GraphDB {
  constructor() {
    this.nodes = {}; // 청크
    this.edges = []; // 관계
  }
  
  addRelation(from, to, type, weight) {
    this.edges.push({
      from: from,
      to: to,
      type: type, // sequential, semantic, hierarchical
      weight: weight
    });
  }
  
  findRelated(chunkId, depth = 2) {
    // BFS로 관련 청크 찾기
  }
}
```

### 3.2 관계 타입
- **Sequential**: 시간 순서
- **Semantic**: 의미적 유사성
- **Hierarchical**: 부모-자식 관계
- **Reference**: 참조 관계

## Phase 4: Smart Loader (Day 4)
**목표**: 지능형 컨텍스트 복원

### 4.1 Query Engine
```javascript
class SmartLoader {
  async query(searchQuery) {
    // 1. TF-IDF 벡터 검색
    const vectors = await this.vectorizer.search(searchQuery);
    
    // 2. 그래프 확장
    const expanded = await this.graph.expand(vectors, depth=2);
    
    // 3. 점수 계산
    const scored = this.scoreChunks(expanded);
    
    // 4. 상위 N개 반환
    return scored.slice(0, 5);
  }
}
```

### 4.2 로드 전략
```bash
# 기본 로드
/cm:load  # 최신 체크포인트

# 쿼리 기반 로드
/cm:load --query "API implementation"

# 시간 기반 로드
/cm:load --date "2025-08-07"

# 태그 기반 로드
/cm:load --tag "backend"
```

## Phase 5: MCP Server (Day 5)
**목표**: 완전 자동화

### 5.1 MCP 서버 구현
```javascript
// mcp-server.js
const { Server } = require('@modelcontextprotocol/sdk');

class MementoMCPServer extends Server {
  constructor() {
    super({
      name: 'claude-memento',
      version: '1.0.0'
    });
  }
  
  async handleRequest(request) {
    switch(request.method) {
      case 'save_context':
        return this.saveContext(request.params);
      case 'load_context':
        return this.loadContext(request.params);
      case 'search':
        return this.search(request.params);
    }
  }
}
```

### 5.2 자동 훅
```javascript
// Auto-save every 5 minutes
setInterval(() => {
  captureContext();
  saveCheckpoint();
}, 5 * 60 * 1000);

// Auto-save on significant events
on('file:save', () => saveCheckpoint());
on('task:complete', () => saveCheckpoint());
```

## 테스트 계획

### 단위 테스트
```bash
npm test -- --coverage
- chunker.test.js
- vectorizer.test.js
- graph.test.js
- loader.test.js
```

### 통합 테스트
```bash
# 전체 플로우 테스트
./test-integration.sh
- 대용량 컨텍스트 저장
- 청크 자동 생성
- 관계 추출
- 쿼리 검색
- 컨텍스트 복원
```

### 성능 벤치마크
- 청킹 속도: >10MB/s
- 검색 응답: <100ms
- 메모리 사용: <500MB
- 복원 정확도: >95%

## 성공 지표

### 정량적 지표
- ✅ 컨텍스트 손실: 0%
- ✅ 복원 정확도: 95%+
- ✅ 응답 시간: <1초
- ✅ 자동화율: 90%+

### 정성적 지표
- ✅ 사용자 개입 최소화
- ✅ 자연스러운 워크플로우
- ✅ 신뢰할 수 있는 복원
- ✅ 직관적인 인터페이스

## 타임라인

| 단계 | 작업 | 예상 시간 | 완료 기준 |
|------|------|-----------|-----------|
| Day 1 | CLAUDE.md 통합 | 1.5h | Claude Code 인식 |
| Day 2 | 청크 시스템 | 2h | 자동 청킹 작동 |
| Day 3 | 그래프 DB | 3h | 관계 검색 가능 |
| Day 4 | 스마트 로더 | 2h | 쿼리 검색 작동 |
| Day 5 | MCP 서버 | 4h | 완전 자동화 |

**총 예상 시간**: 12.5시간

## 다음 단계

1. **즉시 시작**: CLAUDE.md 파일 업데이트
2. **프로토타입**: 청크 시스템 활성화
3. **테스트**: 실제 세션에서 검증
4. **반복**: 피드백 기반 개선
5. **배포**: 전체 통합 완료

---

*이 계획은 점진적 구현을 통해 각 단계마다 즉시 가치를 제공합니다.*
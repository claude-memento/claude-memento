# 📚 Claude Memento 사용 예제

이 파일은 Claude Memento의 실제 사용 예제를 보여줍니다.

## 🎯 시나리오: 웹 애플리케이션 개발

### 1. 프로젝트 시작
```
User: 새로운 웹 애플리케이션 프로젝트를 시작하겠습니다. Todo 앱을 만들 예정입니다.

Claude: 네, Todo 웹 애플리케이션 프로젝트를 시작하겠습니다. 어떤 기술 스택을 사용하실 예정인가요?

User: React와 Node.js를 사용할 예정입니다. 먼저 프로젝트 구조를 설정해주세요.

Claude: React와 Node.js 기반의 Todo 앱 프로젝트 구조를 설정하겠습니다.

User: /cm:save "Todo 앱 프로젝트 시작 - React/Node.js 스택 결정"

Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-100000.md
        📄 File: checkpoint-2025-01-20-100000.md
        📏 Size: 2.1KB
        📝 Reason: Todo 앱 프로젝트 시작 - React/Node.js 스택 결정
        🕐 Time: 2025-01-20 10:00:00
```

### 2. 백엔드 개발
```
User: 백엔드 API를 먼저 구현해주세요. Express를 사용하고 TODO CRUD 기능이 필요합니다.

Claude: Express를 사용한 TODO CRUD API를 구현하겠습니다.
[... 코드 구현 ...]

User: /cm:save "Express 백엔드 구현 완료 - CRUD API 동작 확인"

Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-103000.md
```

### 3. 프론트엔드 개발
```
User: 이제 React 프론트엔드를 구현해주세요. Material-UI를 사용하겠습니다.

Claude: Material-UI를 활용한 React 프론트엔드를 구현하겠습니다.
[... 코드 구현 ...]

User: /cm:save "React 프론트엔드 기본 구조 완성"

Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-113000.md
```

### 4. 세션 중단 및 재개
```
[... 점심 시간으로 세션 중단 ...]

User: 아까 작업하던 Todo 앱 개발을 계속하겠습니다.

Claude: 이전 세션을 확인하겠습니다.

User: /cm:load

Claude: 📋 Session Context:
        ==================
        ## Current Work
        - Todo 웹 애플리케이션 개발 중
        - 백엔드: Express CRUD API 완료
        - 프론트엔드: React + Material-UI 기본 구조 완성
        
        ## Open Files
        - server/app.js
        - client/src/App.js
        - client/src/components/TodoList.js
        
        ✅ Context loaded successfully
        
        프론트엔드와 백엔드 연동 작업을 진행하시겠습니까?
```

### 5. 디버깅 과정
```
User: API 호출 시 CORS 에러가 발생합니다.

Claude: CORS 에러를 해결하겠습니다. Express 서버에 CORS 미들웨어를 추가해야 합니다.

User: /cm:save "CORS 에러 발생 - 디버깅 시작"

[... 문제 해결 과정 ...]

User: /cm:save "CORS 문제 해결 - cors 미들웨어 추가"

Claude: ✅ 체크포인트가 생성되었습니다. CORS 문제가 해결되었습니다.
```

### 6. 상태 확인
```
User: /cm:status

Claude: 🧠 Claude Memento Status
        ========================
        
        💾 Memory Status:
          📄 File: claude-memory.md
          📏 Size: 4.5KB
          📝 Lines: 145
          🕐 Modified: 2025-01-20 14:30
          📊 Content: 1 projects, 5 decisions
        
        🔄 Session Status:
          ✅ Active session (recent activity)
          📋 Tasks: 3 completed, 2 pending
        
        📸 Checkpoint Status:
          📁 Total checkpoints: 5
          📅 Recent checkpoints:
            • checkpoint-2025-01-20-143000.md (1.2KB, 5분 ago)
            • checkpoint-2025-01-20-140000.md (2.3KB, 35분 ago)
            • checkpoint-2025-01-20-113000.md (4.1KB, 3시간 ago)
          💿 Total size: 12.8KB
        
        ⚙️ System Status:
          ✅ Configuration: OK
          ⚙️ Settings:
            • Checkpoint retention: 3
            • Auto-save: true
            • Compression: true
          💿 Total disk usage: 18.2KB
          📦 Version: 1.0.0
```

### 7. 체크포인트 목록 확인
```
User: /cm:list

Claude: 📸 Checkpoints (sorted by time)
        ================================
        
        📊 Summary: 5 checkpoints, 12.8KB total
        
        checkpoint-2025-01-20-143000.md      1.2KB  5분 ago
          └─ CORS 문제 해결 - cors 미들웨어 추가
        
        checkpoint-2025-01-20-140000.md      2.3KB  35분 ago
          └─ CORS 에러 발생 - 디버깅 시작
        
        checkpoint-2025-01-20-113000.md      4.1KB  3시간 ago
          └─ React 프론트엔드 기본 구조 완성
        
        checkpoint-2025-01-20-103000.md      3.5KB  4시간 ago
          └─ Express 백엔드 구현 완료 - CRUD API 동작 확인
        
        checkpoint-2025-01-20-100000.md      1.7KB  4시간 ago
          └─ Todo 앱 프로젝트 시작 - React/Node.js 스택 결정
        
        💡 Commands:
          • Load checkpoint: /cm:load <checkpoint-name>
          • View details: /cm:last
          • Create new: /cm:save "reason"
```

## 💡 활용 팁

### 1. 의미 있는 체크포인트 생성
- 기능 단위로 체크포인트 생성
- 디버깅 전후로 체크포인트 생성
- 중요한 결정 사항 후 체크포인트 생성

### 2. 효율적인 세션 관리
- 작업 시작 시 `/cm:load`로 이전 상태 확인
- 작업 종료 시 `/cm:save`로 현재 상태 저장
- 정기적으로 `/cm:status`로 상태 모니터링

### 3. 장기 프로젝트 관리
- 프로젝트별로 체크포인트 이유에 프로젝트명 포함
- 주요 마일스톤마다 상세한 체크포인트 생성
- 정기적으로 오래된 체크포인트 정리

---
*Example Session v1.0.0*
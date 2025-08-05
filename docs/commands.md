# 📋 Commands Reference

Claude Memento의 모든 명령어에 대한 상세 설명입니다.

## 🎯 명령어 개요

Claude Memento는 두 가지 방식으로 사용할 수 있습니다:
1. **Claude Code 내부**: `/cm:` 네임스페이스 사용 
2. **CLI**: `claude-memento` 명령어 사용 (독립 실행)

## 📝 명령어 목록

### `/cm:save` - 체크포인트 생성
현재 상태를 체크포인트로 저장합니다.

**사용법**:
```bash
# Claude Code 내부
/cm:save "작업 완료 이유"
/cm:save --include-files  # 현재 작업 파일 포함
/cm:save --tag "backend,api"  # 태그 추가

# CLI
claude-memento save "작업 완료 이유"
claude-memento save --force  # 확인 없이 저장
```

**옵션**:
- `--include-files`: 현재 작업 파일들을 체크포인트에 포함
- `--compress`: 대용량 체크포인트 압축 활성화  
- `--tag`: 체크포인트에 태그 추가 (쉼표로 구분)
- `--note`: 체크포인트에 상세 설명 추가
- `-f, --force` (CLI 전용): 확인 없이 즉시 저장

**예제**:
```
User: /cm:save "User 인증 API 구현 완료"
Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-143052.md
        📄 File: checkpoint-2025-01-20-143052.md
        📏 Size: 4.2KB
        📝 Reason: User 인증 API 구현 완료
        🕐 Time: 2025-01-20 14:30:52
```

### `/cm:load` - 컨텍스트 복원
저장된 체크포인트나 세션 컨텍스트를 로드합니다.

**사용법**:
```bash
# Claude 내부
/cm:load                    # 최근 컨텍스트 자동 로드
/cm:load checkpoint-name    # 특정 체크포인트 로드

# CLI
claude-memento load
claude-memento load checkpoint-2025-01-20-143052.md
claude-memento load --no-auto  # 자동 복원 비활성화
```

**옵션**:
- `--no-auto`: 5분 이내 세션 자동 복원 비활성화

**예제**:
```
User: /cm:load
Claude: 📋 Session Context:
        ==================
        [이전 세션 내용]
        
        💾 Long-term Memory:
        ===================
        [장기 메모리 내용]
        
        ✅ Context loaded successfully
```

### `/cm:status` - 메모리 상태 확인
현재 메모리 시스템의 전체 상태를 표시합니다.

**사용법**:
```bash
# Claude 내부
/cm:status

# CLI
claude-memento status
```

**출력 내용**:
- 💾 메모리 상태 (크기, 수정일, 내용 요약)
- 🔄 세션 상태 (활성/비활성, 작업 진행률)
- 📸 체크포인트 상태 (개수, 최근 항목, 전체 크기)
- ⚙️ 시스템 상태 (설정, 디스크 사용량, 버전)

### `/cm:last` - 최근 체크포인트 보기
가장 최근에 생성된 체크포인트의 내용을 표시합니다.

**사용법**:
```bash
# Claude 내부
/cm:last

# CLI
claude-memento last
```

**출력 예제**:
```
📸 Last Checkpoint
==================

📄 File: checkpoint-2025-01-20-143052.md
📏 Size: 4.2KB
🕐 Created: 2025-01-20 14:30:52 (5분 전)
📝 Reason: User 인증 API 구현 완료

📋 Content Preview:
-------------------
[체크포인트 내용 미리보기]
```

### `/cm:list` - 체크포인트 목록
저장된 모든 체크포인트의 목록을 표시합니다.

**사용법**:
```bash
# Claude 내부
/cm:list
/cm:list -n 5      # 최근 5개만 표시
/cm:list -s size   # 크기순 정렬

# CLI
claude-memento list
claude-memento list --limit 10
claude-memento list --sort size
```

**옵션**:
- `-n, --limit`: 표시할 체크포인트 개수 (기본: 10)
- `-s, --sort`: 정렬 기준 (time|size, 기본: time)

### `/cm:config` - 설정 관리
Claude Memento의 설정을 확인하고 변경합니다.

**사용법**:
```bash
# Claude Code 내부
/cm:config --list                   # 전체 설정 표시
/cm:config --get key                # 특정 설정값 확인
/cm:config --set key value          # 설정값 변경
/cm:config --reset                  # 기본값으로 초기화

# CLI
claude-memento config show
claude-memento config get checkpoint.retention
claude-memento config set checkpoint.retention 5
claude-memento config reset
```

### `/cm:hooks` - 훅 시스템 관리
Claude Memento의 훅 시스템을 관리합니다.

**사용법**:
```bash
# Claude Code 내부  
/cm:hooks list                      # 모든 훅 목록
/cm:hooks create pre checkpoint my-hook  # 새 훅 생성
/cm:hooks edit my-hook              # 훅 편집
/cm:hooks enable my-hook            # 훅 활성화
/cm:hooks disable my-hook           # 훅 비활성화
/cm:hooks test my-hook              # 훅 테스트 실행

# CLI
claude-memento hooks list
claude-memento hooks create pre checkpoint notification-hook
claude-memento hooks test notification-hook
```

**훅 이벤트 타입**:
- `checkpoint`: 체크포인트 생성 시
- `load`: 체크포인트 로드 시  
- `cleanup`: 정리 작업 시

**훅 실행 단계**:
- `pre`: 작업 실행 전
- `post`: 작업 실행 후


**주요 설정 항목**:
```json
{
  "checkpoint": {
    "retention": 3,           // 보관할 체크포인트 개수
    "auto_save": true,        // 자동 저장 활성화
    "interval": 900,          // 자동 저장 간격 (초)
    "strategy": "full"        // 체크포인트 전략
  },
  "memory": {
    "max_size": "10MB",       // 최대 메모리 크기
    "compression": true,      // 압축 사용
    "format": "markdown"      // 저장 형식
  },
  "session": {
    "timeout": 300,           // 세션 타임아웃 (초)
    "auto_restore": true      // 자동 복원
  }
}
```

## 🔧 고급 사용법

### 파이프라인 사용
```bash
# 체크포인트 검색
claude-memento list | grep "API"

# 오래된 체크포인트 찾기
claude-memento list -n 50 | tail -10
```

### 스크립트에서 사용
```bash
#!/bin/bash
# 자동 백업 스크립트

while true; do
    claude-memento save "자동 백업 - $(date)"
    sleep 1800  # 30분마다
done
```

### 별칭 설정
```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
alias cms='claude-memento save'
alias cml='claude-memento load'
alias cmst='claude-memento status'
```

## 📊 명령어 흐름도

```
시작
 │
 ├─ /cm:save ──→ 체크포인트 생성 ──→ 오래된 체크포인트 정리
 │
 ├─ /cm:load ──→ 최근 세션 확인 ──┬→ 5분 이내: 세션 복원
 │                                └→ 5분 초과: 체크포인트 로드
 │
 ├─ /cm:status ──→ 전체 상태 수집 ──→ 포맷팅 ──→ 출력
 │
 ├─ /cm:last ──→ 최신 체크포인트 찾기 ──→ 내용 표시
 │
 ├─ /cm:list ──→ 체크포인트 스캔 ──→ 정렬 ──→ 목록 출력
 │
 └─ /cm:config ──→ 설정 파일 읽기 ──→ 작업 수행 ──→ 저장
```

## 💡 팁과 트릭

1. **빠른 저장**: 이유를 생략하면 "Manual checkpoint"로 저장됩니다.
2. **부분 매칭**: 체크포인트 이름의 일부만으로도 로드할 수 있습니다.
3. **자동 정리**: retention 설정에 따라 오래된 체크포인트는 자동 삭제됩니다.
4. **병렬 세션**: 여러 터미널에서 동시에 사용 가능합니다.

---
*Commands Reference v1.0.0*
# 🔌 SuperClaude Integration Guide

Claude Memento를 SuperClaude Framework와 통합하는 방법을 설명합니다.

## 📋 전제 조건

- `~/.claude/` 디렉토리 구조 (SuperClaude 없이도 독립 설치 가능)
- Bash 환경
  - macOS/Linux: 기본 터미널
  - Windows: Git Bash, WSL, 또는 Cygwin

## 🚀 설치 및 통합

### 1. 자동 설치
```bash
# Claude Memento 저장소 클론
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 설치 스크립트 실행
./install.sh
```

### 2. 수동 설치
```bash
# 1. 디렉토리 생성
mkdir -p ~/.claude/memento/{checkpoints,config,logs}
mkdir -p ~/.claude/commands

# 2. 파일 복사
cp -r src/* ~/.claude/memento/
cp commands/* ~/.claude/commands/

# 3. 실행 권한 부여
chmod +x ~/.claude/memento/*.sh
chmod +x ~/.claude/memento/*/*.sh
chmod +x ~/.claude/commands/cm-*.sh

# 4. 설정 파일 생성
cp config/default.json ~/.claude/memento/config/
```

## 🏗️ 아키텍처

### 디렉토리 구조
```
~/.claude/
├── CLAUDE.md              # SuperClaude 메인 설정
├── memento/               # Claude Memento 설치 위치
│   ├── checkpoints/       # 체크포인트 저장소
│   ├── config/           # 설정 파일
│   ├── logs/             # 로그 파일
│   ├── commands/         # 명령어 구현
│   ├── core/             # 핵심 기능
│   ├── utils/            # 유틸리티
│   ├── claude-memory.md  # 장기 메모리
│   └── claude-context.md # 세션 컨텍스트
└── commands/             # SuperClaude 명령어
    ├── cm-save.sh        # /cm:save 래퍼
    ├── cm-load.sh        # /cm:load 래퍼
    ├── cm-status.sh      # /cm:status 래퍼
    └── ...
```

### 명령어 통합 방식

1. **명령어 네임스페이스**: `/cm:` 프리픽스 사용
2. **래퍼 스크립트**: `~/.claude/commands/cm-*.sh`
3. **실제 구현**: `~/.claude/memento/commands/*.sh`

## 📝 SuperClaude 설정 추가

### CLAUDE.md 수정
`~/.claude/CLAUDE.md` 파일에 다음 내용을 추가:

```markdown
## Claude Memento Integration

메모리 관리 확장이 설치되어 있습니다. 다음 명령어를 사용할 수 있습니다:

- `/cm:save [reason]` - 체크포인트 생성
- `/cm:load [checkpoint]` - 컨텍스트 로드
- `/cm:status` - 메모리 상태 확인
- `/cm:last` - 최근 체크포인트 보기
- `/cm:list` - 체크포인트 목록
- `/cm:config` - 설정 관리

### 자동 체크포인트
15분마다 또는 중요한 작업 완료 시 자동으로 체크포인트를 생성합니다.
```

### 명령어 등록
SuperClaude가 명령어를 인식하도록 `~/.claude/commands/cm-commands.json` 파일이 자동 생성됩니다:

```json
{
  "namespace": "cm",
  "description": "Claude Memento - Memory Management",
  "commands": {
    "save": {
      "description": "Create a checkpoint",
      "usage": "/cm:save [reason]",
      "handler": "memento/commands/save.sh"
    },
    // ... 다른 명령어들
  }
}
```

## 🔧 커스터마이징

### 설정 변경
```bash
# 설정 보기
claude-memento config show

# 체크포인트 보관 개수 변경
claude-memento config set checkpoint.retention 5

# 자동 저장 간격 변경 (초 단위)
claude-memento config set checkpoint.interval 1800
```

### 환경 변수
```bash
# 메멘토 디렉토리 위치 변경
export CLAUDE_MEMENTO_DIR="$HOME/.claude/memento"

# 로그 레벨 설정 (1=ERROR, 2=WARN, 3=INFO, 4=DEBUG)
export LOG_LEVEL=3
```

## 🎯 사용 예제

### Claude 내에서 사용
```
User: 백엔드 API 구현을 시작하겠습니다.
Claude: 네, 백엔드 API 구현을 시작하겠습니다.

User: /cm:save "백엔드 API 구현 시작"
Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-143052.md

[... 작업 진행 ...]

User: /cm:save "User 모델 및 인증 API 완료"
Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-01-20-151523.md

[... 다음 세션 ...]

User: /cm:load
Claude: 📋 이전 세션을 복원했습니다. User 모델과 인증 API가 완료된 상태입니다.
        다음 작업을 계속 진행하시겠습니까?
```

### CLI에서 직접 사용
```bash
# 체크포인트 생성
claude-memento save "기능 구현 완료"

# 상태 확인
claude-memento status

# 마지막 체크포인트 보기
claude-memento last
```

## 🔍 문제 해결

### 명령어가 인식되지 않을 때
1. 명령어 파일 권한 확인: `ls -la ~/.claude/commands/cm-*.sh`
2. 실행 권한 부여: `chmod +x ~/.claude/commands/cm-*.sh`
3. SuperClaude 재시작

### 체크포인트가 생성되지 않을 때
1. 디렉토리 권한 확인: `ls -la ~/.claude/memento/checkpoints/`
2. 디스크 공간 확인: `df -h`
3. 로그 확인: `tail -f ~/.claude/memento/logs/memento.log`

### 설정이 적용되지 않을 때
1. 설정 파일 확인: `cat ~/.claude/memento/config/default.json`
2. JSON 유효성 검증: `jq . ~/.claude/memento/config/default.json`
3. 기본값으로 리셋: `claude-memento config reset`

## 🤝 호환성

### SuperClaude 버전
- v1.0.0 이상 지원
- 명령어 시스템이 `/prefix:command` 형식을 지원해야 함

### 운영체제
- macOS: 완전 지원 (네이티브)
- Linux: 완전 지원 (네이티브)
- Windows: 완전 지원 (Git Bash/WSL/Cygwin)

## 📚 추가 리소스

- [Claude Memento 문서](./docs/README.md)
- [SuperClaude 문서](https://github.com/anthropics/superclaude)
- [문제 신고](https://github.com/claude-memento/claude-memento/issues)

---
*Integration Guide v1.0.0*
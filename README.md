# 🧠 Claude Memento - Memory Extension for Claude Code

Claude Memento는 Claude Code를 위한 메모리 관리 확장 프로그램입니다. 대화 중 발생할 수 있는 메모리 리셋 문제를 해결하고, 장기 프로젝트 작업의 연속성을 보장합니다.

**📢 Status**: 초기 릴리스 - 지속적으로 개선 중입니다!

## 주요 기능 ✨

### 핵심 기능
- 💾 **자동 메모리 백업**: 중요한 작업 상태와 컨텍스트를 자동으로 저장
- 🔄 **세션 연속성**: 다음 대화에서 이전 작업을 정확히 이어갈 수 있음
- 📝 **지식 축적**: 프로젝트별 결정사항과 컨텍스트를 영구 보존
- 🎯 **Claude Code 통합**: `/cm:` 네임스페이스로 직접 사용
- 🔐 **안전한 설치**: 기존 설정을 덮어쓰지 않는 비파괴적 설치

### 명령어 시스템 🛠️
Claude Code 내에서 사용할 수 있는 7개의 명령어:

**메모리 관리**: `/cm:save`, `/cm:load`, `/cm:status`  
**체크포인트**: `/cm:list`, `/cm:last`  
**설정**: `/cm:config`, `/cm:hooks`

## 설치 방법 📦

Claude Memento는 단일 스크립트로 간단하게 설치됩니다.

### 전제 조건
- Claude Code 설치 (또는 `~/.claude/` 디렉토리)
- Bash 환경 (Windows는 Git Bash, WSL 또는 PowerShell)

### macOS / Linux
```bash
# 1. 저장소 클론
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 2. 설치 스크립트 실행
./install.sh

# 3. Claude Code에서 사용
# /cm:status
```

### Windows

#### Git Bash (권장)
```bash
# 1. Git Bash 실행

# 2. 저장소 클론
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 3. 설치 스크립트 실행
bash install.sh

# 4. Claude Code에서 사용
# /cm:status
```

#### PowerShell
```powershell
# 1. PowerShell을 관리자 권한으로 실행

# 2. 저장소 클론
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 3. PowerShell 설치 스크립트 실행
.\install.ps1

# 4. Claude Code에서 사용
# /cm:status
```

### 🔐 백업 및 복원

Claude Memento는 설치 시 기존 `.claude` 디렉토리 전체를 자동으로 백업합니다:

```bash
# 설치 시 자동으로 백업 생성
./install.sh
# 📦 Full backup created: ~/.claude_backup_20250805_143052

# 백업 복원하기
~/.claude_backup_20250805_143052/restore.sh

# 제거 시 백업 위치 확인
./uninstall.sh
# 📦 Installation backups:
#    ~/.claude_backup_20250805_143052
#       Backup date: 2025-08-05 14:30:52
#       Restore command: ~/.claude_backup_20250805_143052/restore.sh
```

Windows PowerShell 사용자는:
```powershell
# 백업 복원
~\.claude_backup_20250805_143052\restore.ps1
```

## 사용법 📖

### Claude Code 내에서 사용
```
User: /cm:save "백엔드 API 구현 완료"
Claude: ✅ 체크포인트가 생성되었습니다: checkpoint-2025-08-05-143052.md

User: /cm:status
Claude: 📊 메모리 상태:
- 영구 메모리: 프로젝트 3개, 설정 12개
- 세션 컨텍스트: 활성 (45분 경과)
- 체크포인트: 3개 (최근: 5분 전)

User: /cm:list
Claude: 📋 저장된 체크포인트:
1. checkpoint-2025-08-05-143052.md - "백엔드 API 구현 완료"
2. checkpoint-2025-08-05-120315.md - "프론트엔드 컴포넌트 작업"
3. checkpoint-2025-08-05-094521.md - "프로젝트 초기 설정"
```

### 명령어 참조

| 명령어 | 설명 | 예제 |
|--------|------|------|
| `/cm:save` | 체크포인트 생성 | `/cm:save "작업 완료"` |
| `/cm:load` | 컨텍스트 복원 | `/cm:load` |
| `/cm:status` | 메모리 상태 확인 | `/cm:status` |
| `/cm:last` | 최근 체크포인트 | `/cm:last` |
| `/cm:list` | 체크포인트 목록 | `/cm:list` |
| `/cm:config` | 설정 관리 | `/cm:config show` |
| `/cm:hooks` | 훅 관리 | `/cm:hooks list` |

## 작동 방식 🔄

Claude Memento는 Claude Code를 향상시키는 방식:

1. **비파괴적 설치** - CLAUDE.md에 독립된 섹션을 추가하여 통합
2. **명령어 네임스페이스** - `/cm:` 명령어로 충돌 없이 사용
3. **자동 백업** - 설치 시 전체 `.claude` 디렉토리 백업
4. **스마트 제거** - 추가한 부분만 정확히 제거

## 제거 방법 🗑️

### macOS / Linux
```bash
# 데이터를 보존하면서 제거
./uninstall.sh --keep-data

# 완전 제거
./uninstall.sh
```

### Windows PowerShell
```powershell
# 데이터를 보존하면서 제거
.\uninstall.ps1 -KeepData

# 완전 제거
.\uninstall.ps1
```

## 아키텍처 🏗️

```
claude-memento/
├── src/                     # 소스 코드
│   ├── core/               # 핵심 기능
│   ├── commands/           # 명령어 구현
│   └── utils/              # 유틸리티
├── commands/                # Claude Code 명령어 정의
├── templates/               # 설치 템플릿
├── install.sh              # Unix/Linux 설치
├── install.ps1             # Windows PowerShell 설치
├── uninstall.sh            # Unix/Linux 제거
└── uninstall.ps1           # Windows PowerShell 제거
```

### 설치 후 구조
```
~/.claude/
├── CLAUDE.md               # Claude Memento 섹션 추가됨
├── commands/
│   └── cm/                # Claude Memento 명령어들
├── memento/               # Claude Memento 시스템
│   ├── checkpoints/       # 저장된 체크포인트
│   ├── config/            # 설정 파일
│   └── logs/              # 로그 파일
└── [기존 파일들 그대로 유지]
```

## 설정 ⚙️

`~/.claude/memento/config/default.json`:
```json
{
  "checkpoint": {
    "retention": 10,         // 보관할 체크포인트 수
    "auto_save": true,       // 자동 저장 활성화
    "interval": 900,         // 자동 저장 간격 (초)
    "strategy": "full"       // 저장 전략
  },
  "memory": {
    "max_size": "10MB",      // 최대 메모리 크기
    "compression": true,     // 압축 사용
    "format": "markdown"     // 저장 형식
  }
}
```

## 운영체제 호환성 🖥️

| OS | 지원 | 환경 | 설치 방법 |
|----|------|------|----------|
| macOS | ✅ | Native | `./install.sh` |
| Linux | ✅ | Native | `./install.sh` |
| Windows | ✅ | Git Bash | `bash install.sh` |
| Windows | ✅ | PowerShell | `.\install.ps1` |
| Windows | ✅ | WSL | `./install.sh` |

## FAQ 🙋

**Q: SuperClaude와 함께 사용할 수 있나요?**  
A: 네! Claude Memento는 독립적으로 작동하며 SuperClaude와 충돌하지 않습니다.

**Q: 설치가 기존 설정을 덮어쓰나요?**  
A: 아니요. 비파괴적 설치로 기존 설정은 그대로 유지됩니다.

**Q: 백업은 어디에 저장되나요?**  
A: `~/.claude_backup_TIMESTAMP` 형식으로 홈 디렉토리에 저장됩니다.

**Q: 데이터만 삭제하고 싶어요.**  
A: `~/.claude/memento/checkpoints/` 디렉토리를 직접 삭제하면 됩니다.

## 기여하기 🤝

기여를 환영합니다! 다음 영역에서 도움이 필요합니다:
- 🐛 **버그 리포트** - 문제를 발견하면 알려주세요
- 📝 **문서 개선** - 더 나은 설명을 도와주세요
- 🧪 **테스트** - 다양한 환경에서 테스트
- 💡 **아이디어** - 새로운 기능 제안

## 라이선스 📄

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 관련 링크 🔗

- [SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) - 영감을 받은 프로젝트
- [Claude Code Documentation](https://www.anthropic.com/claude) - Claude 공식 문서
- [Issues](https://github.com/claude-memento/claude-memento/issues) - 버그 리포트 및 기능 요청

---
*Version: 1.0.0*  
*장기 프로젝트 작업을 위한 메모리 확장*
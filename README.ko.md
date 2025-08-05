# Claude Memento v1.0 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/issues)
[![GitHub stars](https://img.shields.io/github/stars/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/stargazers)

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

Claude Code의 대화 간 컨텍스트를 보존하고 장기 프로젝트의 연속성을 보장하는 메모리 관리 확장 프로그램입니다.

**📢 현재 상태**: 초기 릴리스 - 지속적으로 개선 중! 사용 경험을 개선하면서 일부 문제가 있을 수 있습니다.

## Claude Memento란? 🤔

Claude Memento는 Claude Code의 컨텍스트 손실 문제를 다음과 같은 기능으로 해결합니다:
- 💾 **자동 메모리 백업**: 중요한 작업 상태와 컨텍스트를 자동 저장
- 🔄 **세션 연속성**: 이전 작업을 원활하게 재개
- 📝 **지식 축적**: 프로젝트 결정사항을 영구 저장
- 🎯 **네이티브 Claude Code 통합**: `/cm:` 명령어 네임스페이스 제공
- 🔐 **비파괴적 설치**: 기존 설정을 보존하는 안전한 설치

## 현재 상태 📊

**잘 작동하는 기능:**
- 핵심 메모리 관리 시스템
- 7개의 통합된 Claude Code 명령어
- 크로스 플랫폼 설치 (macOS, Linux, Windows)
- 자동 압축 및 인덱싱
- 커스터마이징을 위한 훅 시스템

**알려진 제한사항:**
- 초기 릴리스로 예상되는 버그 존재
- 로컬 저장소로 제한 (클라우드 동기화 예정)
- 현재 단일 프로필만 지원
- 수동 체크포인트 관리

## 주요 기능 ✨

### 명령어 🛠️
메모리 관리를 위한 7가지 필수 명령어:

**메모리 작업:**
- `/cm:save` - 설명과 함께 현재 상태 저장
- `/cm:load` - 특정 체크포인트 로드
- `/cm:status` - 시스템 상태 보기

**체크포인트 관리:**
- `/cm:list` - 모든 체크포인트 목록
- `/cm:last` - 가장 최근 체크포인트 로드

**설정:**
- `/cm:config` - 설정 보기/편집
- `/cm:hooks` - 훅 스크립트 관리

### 스마트 기능 🎭
- **자동 압축**: 대용량 컨텍스트를 효율적으로 저장
- **지능형 인덱싱**: 빠른 체크포인트 검색 및 검색
- **훅 시스템**: 저장/로드 이벤트에 대한 커스텀 스크립트
- **증분 백업**: 저장소 최적화를 위해 변경사항만 저장
- **전체 시스템 백업**: 설치 전 ~/.claude 디렉토리의 전체 백업 생성
- **간편한 복원**: 백업에 포함된 원클릭 복원 스크립트

## 설치 📦

Claude Memento는 단일 스크립트로 설치됩니다.

### 필수 조건
- Claude Code 설치 (또는 `~/.claude/` 디렉토리 존재)
- Bash 환경 (Windows에서는 Git Bash, WSL 또는 PowerShell)

### 빠른 설치

**macOS / Linux:**
```bash
# 클론 및 설치
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# Claude Code에서 확인
# /cm:status
```

**Windows (PowerShell):**
```powershell
# 저장소 클론
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 필요시 실행 정책 설정
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 설치 프로그램 실행
.\install.ps1
```

**Windows (Git Bash):**
```bash
# 클론 및 설치
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh
```

## 작동 방식 🔄

1. **상태 캡처**: Claude Memento가 현재 작업 컨텍스트를 캡처
2. **압축**: 대용량 컨텍스트를 지능적으로 압축
3. **저장**: 메타데이터와 타임스탬프와 함께 체크포인트 저장
4. **검색**: 모든 체크포인트를 로드하여 전체 컨텍스트 복원
5. **통합**: 원활한 워크플로우를 위한 네이티브 Claude Code 명령어

### 아키텍처 개요

```
Claude Code 세션
    ↓
/cm:save 명령어
    ↓
컨텍스트 처리 → 압축 → 저장
                        ↓
                   체크포인트
                        ↓
                ~/.claude/memento/
                        ↓
/cm:load 명령어 ← 압축 해제 ← 검색
    ↓
복원된 세션
```

## 사용 예시 💡

### 기본 워크플로우
```bash
# 새 기능 시작
/cm:save "초기 기능 설정 완료"

# 중요한 진행 후
/cm:save "API 엔드포인트 구현"

# 다음 날 - 컨텍스트 복원
/cm:last

# 또는 특정 체크포인트 로드
/cm:list
/cm:load checkpoint-20240119-143022
```

### 고급 사용법
```bash
# 자동 저장 간격 설정
/cm:config set autoSave true
/cm:config set saveInterval 300

# 커스텀 훅 추가
/cm:hooks add post-save ./scripts/backup-to-cloud.sh
/cm:hooks add pre-load ./scripts/validate-checkpoint.sh

# 시스템 상태 확인
/cm:status --verbose
```

## 설정 🔧

기본 설정 (`~/.claude/memento/config/default.json`):
```json
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
```

## 프로젝트 구조 📁

```
claude-memento/
├── src/
│   ├── core/          # 핵심 메모리 관리
│   ├── commands/      # 명령어 구현
│   ├── utils/         # 유틸리티 및 헬퍼
│   └── bridge/        # Claude Code 통합
├── templates/         # 설정 템플릿
├── commands/          # 명령어 정의
├── docs/             # 문서
└── examples/         # 사용 예시
```

## 문제 해결 🔍

### 일반적인 문제

**명령어가 작동하지 않음:**
```bash
# 명령어가 설치되었는지 확인
ls ~/.claude/commands/cm/

# 상태 명령어 확인
/cm:status
```

**설치 실패:**
```bash
# 권한 확인
chmod +x install.sh
./install.sh --verbose
```

**메모리 로드 오류:**
```bash
# 체크포인트 무결성 확인
/cm:status --check
# 필요시 복구
./src/utils/repair.sh
```

**설치 후 경로 구조 문제:**
```bash
# "file not found" 오류로 명령어가 실패하는 경우
# 잘못된 설치가 원인일 수 있습니다
# 업데이트된 스크립트로 재설치:
./uninstall.sh && ./install.sh
```

**권한 오류:**
```bash
# "permission denied" 오류가 발생하는 경우
# 파일 권한 확인
ls -la ~/.claude/memento/src/**/*.sh

# 필요시 수동으로 권한 수정
find ~/.claude/memento/src -name "*.sh" -type f -exec chmod +x {} \;
```

## 기여하기 🤝

기여를 환영합니다! 자세한 내용은 [기여 가이드](CONTRIBUTING.md)를 참조하세요.

1. 저장소 포크
2. 기능 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add amazing feature'`)
4. 브랜치 푸시 (`git push origin feature/amazing-feature`)
5. Pull Request 열기

## 로드맵 🗺️

**버전 1.1:**
- [ ] 클라우드 백업 지원
- [ ] 다중 프로필 관리
- [ ] 실시간 동기화 기능

**버전 2.0:**
- [ ] 웹 UI 대시보드
- [ ] 팀 협업 기능
- [ ] 고급 검색 및 필터링
- [ ] 다른 AI 도구와의 통합

## FAQ ❓

**Q: 내 데이터는 안전한가요?**
A: 모든 데이터는 홈 디렉토리에 로컬로 저장됩니다. 클라우드 기능은 암호화를 포함할 예정입니다.

**Q: 여러 프로젝트에서 사용할 수 있나요?**
A: 네! 체크포인트는 프로젝트 컨텍스트별로 자동으로 구성됩니다.

**Q: Claude Code가 업데이트되면 어떻게 되나요?**
A: Claude Memento는 Claude Code 업데이트와 호환되도록 설계되었습니다.

## 라이선스 📄

이 프로젝트는 MIT 라이선스 하에 라이선스가 부여됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 감사의 말 🙏

피드백과 기여를 해주신 Claude Code 커뮤니티에 특별히 감사드립니다.

---

**도움이 필요하신가요?** [문서](docs/README.md)를 확인하거나 [이슈를 열어주세요](https://github.com/claude-memento/claude-memento/issues).

**Claude Memento가 마음에 드시나요?** [GitHub](https://github.com/claude-memento/claude-memento)에서 ⭐를 주세요!
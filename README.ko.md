# Claude Memento v1.0.1 🧠

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

## Claude Code 에이전트 통합 🤖

Claude Memento는 여러 에이전트 간의 향상된 컨텍스트 관리를 위한 **Context-Manager-Memento** 에이전트를 포함합니다.

### 에이전트 기능
- **자동 컨텍스트 캡처**: 실시간 모니터링 및 체크포인트 생성
- **스마트 청킹**: 10K 토큰 이상의 컨텍스트를 의미론적 경계 감지로 처리
- **멀티 에이전트 조정**: 전문 에이전트 간의 원활한 핸드오프
- **지능형 압축**: 정확도를 유지하면서 30-50% 토큰 감소

### 주요 에이전트 명령어
```bash
# 핵심 작업
/cm:save "프로젝트 마일스톤 완료"
/cm:load checkpoint-id
/cm:last

# 스마트 검색
/cm:chunk search "인증"
/cm:chunk graph --depth 2

# 설정
/cm:config auto-save.interval 15
/cm:status
```

### 에이전트 장점
- **40-60% 토큰 사용량 감소** - 스마트 컨텍스트 로딩을 통해
- **자동 세션 연속성** - 지속적인 체크포인트로
- **에이전트 간 메모리 공유** - 복잡한 다단계 워크플로우를 위해
- **성능 최적화** - 지능형 캐싱으로

자세한 에이전트 사용법은 [에이전트 사용 가이드](docs/AGENT_USAGE.md)를 참조하세요.

## 설치 📦

Claude Memento는 단일 스크립트로 설치됩니다.

### 필수 조건
- Claude Code 설치 (또는 `~/.claude/` 디렉토리 존재)
- Bash 환경 (Windows에서는 Git Bash, WSL 또는 PowerShell)
- Node.js (그래프 데이터베이스 및 벡터화 기능용)
- jq (JSON 처리용 - 누락시 자동 설치)

### 빠른 설치

**macOS / Linux:**
```bash
# 클론 및 설치
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# 설치 확인
/cm:status
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

### 설치 기능
- ✅ **자동 백업**: 설치 전 전체 백업 생성
- ✅ **비파괴적**: 기존 CLAUDE.md 내용 보존
- ✅ **크로스 플랫폼**: macOS, Linux, Windows 지원
- ✅ **의존성 검사**: 누락된 의존성 검증 및 설치
- ✅ **롤백 지원**: 필요시 쉬운 복원

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

### 설정 구조 (`~/.claude/memento/config/settings.json`)

```json
{
  "autoSave": {
    "enabled": true,        // Boolean: 자동 저장 활성화
    "interval": 60,         // Number: 저장 간격 (초)
    "onSessionEnd": true    // Boolean: 세션 종료시 저장
  },
  "chunking": {
    "enabled": true,        // Boolean: 청크 시스템 활성화
    "threshold": 10240,     // Number: 청킹 임계값 (바이트)
    "chunkSize": 2000,      // Number: 개별 청크 크기
    "overlap": 50           // Number: 청크 간 겹침
  },
  "memory": {
    "maxSize": 1048576,     // Number: 최대 메모리 사용량
    "compression": true     // Boolean: 압축 활성화
  },
  "search": {
    "method": "tfidf",      // String: 검색 방법 (tfidf/simple)
    "maxResults": 20,       // Number: 최대 검색 결과
    "minScore": 0.1         // Number: 최소 유사도 점수
  }
}
```

**⚠️ 중요**: 문자열이 아닌 실제 boolean/number 타입을 사용하세요 (`"true"`가 아닌 `true`).

### 설정 명령어
```bash
# 현재 설정 보기
/cm:config

# 60초 간격으로 자동 저장 활성화
/cm:auto-save enable
/cm:auto-save config interval 60

# 시스템 상태 확인
/cm:status
```

## 프로젝트 구조 📁

```
claude-memento/
├── src/
│   ├── commands/      # 명령어 구현
│   ├── core/          # 핵심 메모리 관리
│   ├── chunk/         # 그래프 DB 및 청킹 시스템
│   ├── config/        # 설정 관리
│   ├── hooks/         # 훅 시스템
│   └── bridge/        # Claude Code 통합
├── commands/cm/       # 명령어 정의
├── test/             # 테스트 스크립트
├── docs/             # 문서
└── examples/         # 사용 예시

런타임 구조 (~/.claude/memento/):
├── checkpoints/      # 저장된 체크포인트
├── chunks/           # 그래프 DB 및 청크 저장소
├── config/           # 런타임 설정
└── src/              # 설치된 시스템 파일
```

## 고급 기능 🚀

### 그래프 데이터베이스 시스템
Claude Memento는 고급 그래프 기반 청크 관리 시스템을 포함합니다:

- **TF-IDF 벡터화**: 의미적 유사도 검색
- **그래프 관계**: 자동 콘텐츠 관계 발견
- **스마트 로딩**: 쿼리 기반 선택적 컨텍스트 복원
- **성능**: 50ms 미만 검색 시간

### 청크 관리
```bash
# 키워드로 청크 검색
/cm:chunk search "API implementation"

# 모든 청크 목록
/cm:chunk list

# 의미적 관계 구축
/cm:chunk build-relations

# 시스템 통계 조회
/cm:chunk stats
```

## 제거 🗑️

### 안전한 제거 옵션

Claude Memento는 데이터 보존 옵션이 포함된 포괄적인 제거 기능을 제공합니다:

**완전 제거:**
```bash
# 모든 것 제거 (영구적 데이터 삭제)
./uninstall.sh
```

**데이터 보존:**
```bash
# 체크포인트 및 청크 유지
./uninstall.sh --keep-data

# PowerShell 동등 명령어
.\uninstall.ps1 -KeepData
```

**강제 모드 (확인 생략):**
```bash
# 자동화된 제거
./uninstall.sh --force

# 데이터 보존과 함께
./uninstall.sh --keep-data --force
```

### 제거되는 항목
- ✅ **실행 중인 프로세스**: 그레이스풀 종료와 함께 자동 중지
- ✅ **Claude Memento 섹션**: CLAUDE.md에서 제거 (파일 보존)
- ✅ **명령어 파일**: 모든 `/cm:` 명령어 제거
- ✅ **설치 파일**: 완전한 시스템 정리
- ✅ **임시 파일**: PID 파일 및 캐시 정리

### 데이터 보존
`--keep-data` 사용시:
- 체크포인트를 `~/claude-memento-backup-[timestamp]/`로 백업
- 설정 파일 보존
- 그래프 데이터베이스 및 청크 유지
- 활성 컨텍스트 파일 저장

## 문제 해결 🔍

### 설치 문제

**명령어가 작동하지 않음:**
```bash
# 설치 확인
/cm:status

# 명령어 파일 확인
ls ~/.claude/commands/cm/
```

**자동 저장이 작동하지 않음:**
```bash
# 설정 확인
/cm:auto-save status

# 필요시 활성화
/cm:auto-save enable
/cm:auto-save config interval 60
```

**그래프 시스템 오류:**
```bash
# 시스템 테스트 실행
cd ~/.claude/memento/test/
./test-chunk-system.sh

# Node.js 설치 확인
node --version
```

### 성능 문제

**느린 검색:**
```bash
# 검색 인덱스 재구축
/cm:chunk build-relations

# 시스템 성능 확인
/cm:status --verbose
```

### 복구 옵션

**백업에서 복원:**
```bash
# 사용 가능한 백업 목록
ls ~/.claude_backup_*/

# 복원 스크립트 실행
~/.claude_backup_[timestamp]/restore.sh
```

**설정 초기화:**
```bash
# 기본값으로 재설정
rm ~/.claude/memento/config/settings.json
/cm:status  # 기본값으로 재생성
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
- [ ] 청크 시각화를 위한 웹 인터페이스
- [ ] 고급 검색 필터 및 쿼리
- [ ] 다국어 콘텐츠 지원

**버전 2.0:**
- [ ] 클라우드 백업 통합
- [ ] 팀 협업 기능
- [ ] 고급 분석 대시보드
- [ ] 다른 AI 도구와의 통합

**최근 업데이트 (v1.0.1):**
- ✅ 프로세스 관리 기능이 향상된 제거 스크립트
- ✅ 적절한 데이터 타입을 사용한 개선된 설정 시스템
- ✅ 의미적 검색이 포함된 그래프 데이터베이스 시스템
- ✅ 백그라운드 데몬을 통한 자동 저장 기능
- ✅ 성능 검증이 포함된 포괄적 테스트 슈트

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

## Star History

<a href="https://www.star-history.com/#claude-memento/claude-memento&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
 </picture>
</a>
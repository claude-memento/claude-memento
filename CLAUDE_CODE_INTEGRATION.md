# Claude Code Integration Guide

Claude Memento는 Claude Code와 완전히 통합되어 `/cm:` 네임스페이스를 통해 사용할 수 있습니다.

## 📁 올바른 폴더 구조

```
~/.claude/commands/
├── sc/           # SuperClaude 명령어들
│   ├── analyze.md
│   ├── build.md
│   └── ...
└── cm/           # Claude Memento 명령어들
    ├── save.md
    ├── load.md
    ├── list.md
    ├── status.md
    ├── config.md
    ├── hooks.md
    └── last.md
```

## 🎯 지원되는 명령어

### 기본 명령어
- `/cm:save` - 현재 대화 컨텍스트 저장
- `/cm:load` - 저장된 컨텍스트 로드
- `/cm:list` - 체크포인트 목록 조회
- `/cm:status` - 시스템 상태 확인
- `/cm:last` - 마지막 체크포인트 빠른 접근

### 고급 명령어  
- `/cm:config` - 설정 관리
- `/cm:hooks` - 훅 시스템 관리

## 🤖 에이전트 지원

Claude Code는 Context-Manager-Memento 에이전트를 통해 향상된 컨텍스트 관리를 지원합니다.

### 에이전트 설치 위치
```
~/.claude/agents/context-manager-memento.md
```

### 에이전트 핵심 기능
- **자동 컨텍스트 캡처**: Claude Code 세션 중 실시간 컨텍스트 모니터링
- **스마트 청킹**: 10K+ 토큰 컨텍스트의 자동 분할 및 관계 추적
- **멀티 에이전트 조정**: 다른 에이전트와의 컨텍스트 공유 및 핸드오프
- **지능형 압축**: 30-50% 토큰 감소로 성능 최적화

### 에이전트 명령어
```bash
# 컨텍스트 관리
/cm:save "Feature implementation complete"
/cm:chunk search "authentication logic"
/cm:chunk graph --depth 2

# 자동 설정
/cm:config auto-save.interval 15
/cm:config checkpoint.compress true
```

### 에이전트 장점
- **토큰 효율성**: 스마트 로딩으로 40-60% 토큰 사용량 감소  
- **세션 연속성**: 자동 체크포인트로 작업 중단 없음
- **에이전트 협업**: 복잡한 다단계 작업에서 효율적 컨텍스트 전달
- **성능 향상**: 지능형 캐싱과 압축으로 응답 속도 개선

자세한 사용법은 [에이전트 사용 가이드](docs/AGENT_USAGE.md)를 참조하세요.

## 🔧 설치 후 확인

```bash
# Claude Code에서 직접 사용
/cm:status

# 첫 체크포인트 생성
/cm:save "Initial setup complete"

# 체크포인트 목록 확인
/cm:list

# 마지막 체크포인트 정보
/cm:last --info

# 설정 확인
/cm:config --list

# 훅 시스템 상태 확인
/cm:hooks list
```

## 🎨 명령어 형태

Claude Code 명령어는 Markdown 형태로 정의되며, frontmatter에 허용된 도구들을 명시합니다:

```markdown
---
allowed-tools: [Read, Write, Bash, Glob, Grep]
description: "Claude Memento - Save conversation context"
---

# /cm:save - Conversation Context Save
```

## ⚡ 자동 브리지

`/cm:` 명령어는 자동으로 해당하는 `.sh` 스크립트로 연결됩니다:

- `/cm:save` → `~/.claude/commands/cm/save.md` → `claude-code-bridge.sh` → `save.sh`
- `/cm:load` → `~/.claude/commands/cm/load.md` → `claude-code-bridge.sh` → `load.sh`

## 🔗 통합 아키텍처

```
Claude Code
    ↓
.md 명령어 파일 (frontmatter + 문서)
    ↓
claude-code-bridge.sh (브리지 스크립트)
    ↓
실제 .sh 구현 파일
    ↓
Claude Memento 코어 시스템
```

이 구조를 통해 Claude Code의 문서화된 명령어 시스템과 Claude Memento의 강력한 쉘 기반 구현을 연결합니다.
# 📚 Claude Memento Documentation

Claude Memento의 상세 문서입니다.

## 📖 목차

1. [시작하기](./getting-started.md)
2. [명령어 참조](./commands.md)
3. [설정 가이드](./configuration.md)
4. [아키텍처](./architecture.md)
5. [API 참조](./api-reference.md)
6. [문제 해결](./troubleshooting.md)

## 🎯 핵심 개념

### Memento 패턴
Claude Memento는 GoF의 Memento 디자인 패턴을 기반으로 합니다:
- **Originator**: Claude의 현재 상태
- **Memento**: 체크포인트 (상태 스냅샷)
- **Caretaker**: 메모리 관리 시스템

### 3계층 메모리 구조
1. **장기 메모리** (`claude-memory.md`)
   - 프로젝트 정보
   - 사용자 선호도
   - 중요 결정사항

2. **세션 컨텍스트** (`claude-context.md`)
   - 현재 작업 상태
   - 열린 파일 목록
   - 실행 중인 프로세스

3. **체크포인트** (`checkpoint-*.md`)
   - 특정 시점의 전체 상태
   - 타임스탬프와 이유 포함
   - 자동 정리 (기본 3개 유지)

## 🚀 빠른 시작

### 설치
```bash
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh
```

### 첫 번째 체크포인트
```bash
# CLI에서
claude-memento save "프로젝트 시작"

# Claude 내에서
/cm:save "프로젝트 시작"
```

### 상태 확인
```bash
# CLI에서
claude-memento status

# Claude 내에서
/cm:status
```

## 💡 사용 시나리오

### 1. 긴 개발 세션
장시간 개발 작업 시 주기적으로 체크포인트를 생성하여 진행 상황을 보존합니다.

### 2. 복잡한 디버깅
디버깅 과정의 각 단계를 체크포인트로 저장하여 나중에 참조할 수 있습니다.

### 3. 팀 협업
체크포인트를 공유하여 팀원들과 작업 내용을 동기화합니다.

### 4. 지식 축적
프로젝트별 결정사항과 패턴을 장기 메모리에 저장하여 재사용합니다.

## 🔧 고급 기능

### 자동 체크포인트
설정된 간격(기본 15분)마다 자동으로 체크포인트를 생성합니다.

### 압축 모드
메모리 사용량을 줄이기 위해 체크포인트를 압축할 수 있습니다.

### 검색 기능
메모리와 체크포인트에서 특정 내용을 검색할 수 있습니다.

### 동기화
Git이나 클라우드 서비스와 연동하여 체크포인트를 백업할 수 있습니다.

## 📊 성능 최적화

### 토큰 효율성
- 선택적 로딩으로 필요한 부분만 로드
- 중복 제거로 메모리 크기 최소화
- 압축 옵션으로 추가 최적화

### 빠른 복원
- 5분 이내 세션은 즉시 복원
- 인덱싱으로 빠른 검색
- 캐싱으로 반복 접근 최적화

## 🤝 기여하기

Claude Memento는 오픈소스 프로젝트입니다. 기여를 환영합니다!

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](../LICENSE) 파일을 참조하세요.

---
*Documentation v1.0.0*
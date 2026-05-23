# Antigravity Agent Harness (에이전트 개발 및 검증 하네스)

본 리포지토리는 Antigravity CLI 환경에서 멀티 에이전트(개발, QA, 보안/린터 감사)를 오케스트레이션하여 자율 코딩, 자동 린트 검사, 기동 테스트 및 오류 피드백 루프를 구축하는 경량 하네스(Harness)입니다.

어떤 프로젝트든 본 하네스 폴더를 연결하기만 하면 에이전트 전용 비동기 검증 인프라를 즉시 사용할 수 있습니다.

---

## 1. 디렉토리 구조 (Directory Structure)

```
my-project/ (대상 소스코드 프로젝트 루트)
├── .agent.config.json         # 프로젝트별 빌드/테스트 설정 파일
└── .agent/                    # 에이전트 하네스 코어 폴더
    ├── bin/                   
    │   ├── init.sh            # 하네스 초기화 스크립트 (가상환경 및 Git 설정)
    │   └── run-test.sh        # 린트 및 기동 테스트 실행 래퍼
    ├── system.md              # 메인 에이전트용 지시문서
    ├── prompts/               # 서브 에이전트 전용 특화 프롬프트
    │   ├── qa_engineer.md     # 기동 테스트 실패 분석 및 디버깅 가이드
    │   └── security_auditor.md# 린트 경고 및 보안 규칙 준수 감사 가이드
    ├── rules/
    │   ├── security.rule.md   # 에이전트 위험 행위(외부 전송, 강제 삭제) 차단 룰
    │   └── guidelines.rule.md # 한국어 주석 강제 등 코드 가독성 룰
    └── hooks/
        ├── on-test-fail.sh      # 테스트 실패 발생 시 호출되는 피드백 훅
        └── post-task.sh         # 임시 아티팩트 및 로그 정리를 위한 가비지 컬렉션(GC) 훅
```

---

## 2. 설치 및 설치 방법 (Installation)

대상 소스코드 프로젝트 루트 경로에서 아래 방식 중 하나를 선택해 하네스를 설치합니다.

### 방법 A: Git Submodule로 연동하기 (권장)
하네스 리포지토리를 서브모듈로 등록하여 간편하게 버전을 관리하고 최신 상태를 업데이트할 수 있습니다.
```bash
# 대상 프로젝트 루트에서 실행
git submodule add <Harness-Repository-URL> .agent
```

### 방법 B: 직접 복사하기
하네스 리포지토리의 `.agent` 폴더 전체를 대상 소스코드 프로젝트 루트에 그대로 복사하여 넣습니다.

---

## 3. 초기화 및 기동 방법 (Getting Started)

### 1단계: 프로젝트 환경 설정
프로젝트 루트 폴더에 `.agent.config.json` 파일을 작성하고 사용 중인 언어와 빌드/테스트 명령어를 기입합니다.
```json
{
  "project_type": "nodejs",
  "lint_command": "npm run lint",
  "test_command": "npm test",
  "src_directory": "./src"
}
```

### 2단계: 하네스 초기화
하네스 쉘 스크립트들을 활성화하고 임시 저장소를 확보하기 위해 초기화 스크립트를 최초 1회 가동합니다.
```bash
# 쉘 스크립트 실행 권한 부여
chmod +x .agent/bin/*.sh .agent/hooks/*.sh

# 초기화 스크립트 실행
./.agent/bin/init.sh
```
* **동작 결과**: `.tmp_artifacts/` 및 `.agent/logs/` 경로가 자동 생성되며, 해당 경로들이 Git 추적에서 제외되도록 `.gitignore` 파일에 규칙이 자동으로 기록됩니다.

---

## 4. 핵심 사용 흐름 (Workflow)

1. **에이전트 가동**: Antigravity CLI가 프로젝트에 진입할 때 `.agent/system.md` 지시문서와 `.agent/rules/` 폴더 내의 규칙을 주입하여 작업을 시작합니다.
2. **테스트 및 검증**: 코드가 수정되거나 새로 작성되면 `./.agent/bin/run-test.sh`를 실행하여 린트 및 기동 상태를 정적 분석합니다.
3. **피드백 루프**: 
   * 만약 테스트나 린트가 실패하면 자동으로 `.agent/hooks/on-test-fail.sh`가 호출되어 상세 오류 메시지를 캡처합니다.
   * 메인 에이전트는 `qa_engineer.md` 프롬프트로 서브 에이전트를 가동해 에러 로그를 분석시키고 자율 디버깅을 진행합니다.
4. **정리 (Garbage Collection)**: 작업이 끝나 성공적으로 반영되면 `./.agent/hooks/post-task.sh`가 임시 로그 및 덤프 파일을 소거합니다.

---

## 5. 커스터마이징 가이드 (Customization)

* **에이전트 규칙 변경**: `rules/guidelines.rule.md`나 `rules/security.rule.md`에 우리 프로젝트 고유의 설계 원칙(예: "모든 코드는 MVC 아키텍처를 따를 것", "한국어 주석은 필수")을 한글로 기술해두면 에이전트가 이를 엄격히 준수합니다.
* **서브 에이전트 확장**: 새로운 전문 능력이 필요하다면 `prompts/` 폴더 내에 마크다운(`*.md`) 형식으로 서브 에이전트 특화 임무를 작성하고, 메인 에이전트가 이를 호출하도록 유도하십시오.

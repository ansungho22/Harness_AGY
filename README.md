# Antigravity Agent Harness (에이전트 개발 및 검증 하네스)

본 리포지토리는 Antigravity CLI 환경에서 멀티 에이전트(개발, QA, 보안/린터 감사, 도메인 전문 개발진)를 오케스트레이션하여 자율 코딩, 자동 린트 검사, 기동 테스트 및 오류 피드백 루프를 구축하는 경량 하네스(Harness)입니다.

**다른 프로젝트에 Git 서브모듈로 연동하여 즉시 재사용할 수 있도록 설계되어 있습니다.**

---

## 1. 하네스 설계 사상 (Architecture Philosophy)

AI 에이전트 중심의 자율 개발 환경에서 가장 자주 발생하는 문제는 **"에이전트의 환각(Hallucination)"**과 **"대화 컨텍스트 누적에 따른 인지 능력 저하"**입니다. 본 하네스는 이 두 가지 한계를 극복하기 위해 설계되었습니다.

1. **'말'이 아닌 '틀'로써의 규제**:
   * 에이전트에게 "코드를 바르게 작성하라"고 문장으로 지시하는 대신, 린터와 기동 테스트를 강제하는 **물리적 차단 틀(Git Pre-commit 훅, CI 파이프라인)**에 에이전트를 가둡니다. 규칙을 위반한 코드는 리포지토리에 저장(Commit)될 수 없습니다.
2. **전문 서브 에이전트 오케스트레이션**:
   * 단일 에이전트에게 모든 책임을 묻지 않고, **QA 엔지니어**, **보안 감사자**, **백엔드 개발자**, **프론트엔드 개발자**, **AI 엔지니어**, **데이터 엔지니어** 등의 독립된 전문 서브 에이전트를 비동기 구동하여 병렬 검증 및 특화 구현을 수행합니다. 이를 통해 메인 에이전트의 컨텍스트 윈도우를 최적으로 유지합니다.
3. **지속 가능한 지식 자산화**:
   * 에이전트가 과거의 맥락을 모른 채 엉뚱한 아키텍처를 도입하는 일을 막기 위해 아키텍처 결정 기록(ADR)과 실패 기록(Failures)을 파일 시스템 상의 지식 저장소(`docs/`)로 유지합니다.

---

## 2. 디렉토리 구조 및 역할 (Directory Structure)

```
my-project/                         # 대상 소스코드 프로젝트 루트
├── AGENTS.md                        # 에이전트 최상위 코딩 수칙 및 동작 지침 (7장 시스템 규약)
├── README.md                        # [본 파일] 하네스 아키텍처 및 사용 명세서
├── .agent.config.json               # 프로젝트별 린트/테스트 CLI 실행 명령어 커스텀 설정
│
├── .agents/                         # ✅ 에이전트 하네스 코어 (Git 서브모듈 본체)
│   ├── plugin.json                  # agy CLI 플러그인 메타데이터 명세
│   ├── agents.md                    # 서브 에이전트 목록 요약 명세
│   │
│   ├── agents/                      # 전문 서브 에이전트 정의 (각 폴더 내 agent.json 보유)
│   │   ├── qa_engineer/             # 기동 테스트 실패 전문 디버깅 에이전트
│   │   ├── security_auditor/        # 린트 및 보안 수칙 감사 에이전트
│   │   ├── backend_developer/       # 고성능 API 및 DB 설계 전문 백엔드 에이전트
│   │   ├── frontend_developer/      # 컴포넌트 재사용 및 UI/UX 스타일 전문 프론트엔드 에이전트
│   │   ├── ai_engineer/             # LLM 연동, RAG 및 벡터 DB 설계 전문 AI 에이전트
│   │   ├── data_engineer/           # ETL 파이프라인 및 대용량 처리 전문 데이터 에이전트
│   │   └── architecture_analyst/    # 전체 구조 및 의존성 분석 전문 설계 에이전트 (AA)
│   │
│   ├── skills/                      # agy 슬래시 커맨드에 연동되는 실행 가능한 스킬 단위
│   │   ├── init/
│   │   │   ├── SKILL.md             # init 스킬 실행 명세서
│   │   │   └── init.sh              # 하네스 초기화 및 Git Hook 동기화 스크립트
│   │   └── run-test/
│   │       ├── SKILL.md             # run-test 스킬 실행 명세서
│   │       └── run-test.sh          # 프로젝트별 린트 및 기동 테스트 실행 래퍼
│   │
│   ├── rules/                       # 에이전트가 준수해야 할 코딩 규칙 명세
│   │   ├── guidelines.rule.md       # 한국어 주석 강제, 클린코드 5대 수칙 등의 가이드라인
│   │   ├── security.rule.md         # 보안 및 안전 위험 명령 통제 규칙
│   │   └── architecture.rule.md    # 계층 구조 침범 방지 및 의존성 역전 아키텍처 규칙
│   │
│   └── hooks/                       # Git 이벤트 연동 자동화 훅 스크립트
│       ├── pre-commit.sh            # git commit 시점 사전 자동 정밀 검사 훅
│       ├── on-test-fail.sh          # 테스트 실패 포착 시 피드백 루프 가동 훅
│       └── post-task.sh             # 잔여 임시 로그 정리를 위한 가비지 컬렉터(GC) 훅
│
└── docs/                            # 에이전트 전용 로컬 지식 저장소
    ├── adr/
    │   └── README.md                # ADR 작성 가이드 및 목적 (에이전트 이정표)
    └── failures/
        └── README.md                # 실패 기록 작성 가이드 및 목적 (에이전트 오작동 차단)
```

> [!NOTE]
> `docs/adr/README.md` 및 `docs/failures/README.md` 파일은 해당 폴더에 접근한 에이전트가 폴더의 존재 목적과 기록 규칙(ADR, 실패 패턴 등)을 스스로 학습할 수 있도록 이정표 역할을 수행하기 위해 독립 보존됩니다.

---

## 3. 설치 및 초기화 (Setup & Getting Started)

### 1단계: 하네스 서브모듈 연동
대상 소스코드 프로젝트 루트 경로에서 Git 서브모듈로 하네스를 연동합니다.
```bash
git submodule add <Harness-Repository-URL> .agents
git submodule update --init --recursive
```

### 2단계: 프로젝트 설정 파일 정의
루트에 `.agent.config.json`을 생성하고 프로젝트 스택에 맞춰 명령어를 정의합니다.
*(최초 1회 수동으로 생성하거나, 아래 3단계 지능형 설정을 통해 자동으로 빌드 가능합니다)*
```json
{
  "project_type": "nodejs",
  "lint_command": "npm run lint",
  "test_command": "npm test",
  "src_directory": "./src"
}
```

지원하는 기술 스택 자동 감지 목록:

| 감지 파일 | 스택 | 기본 린트 | 기본 테스트 |
|-----------|------|----------|------------|
| `package.json` | Node.js | `npm run lint` | `npm test` |
| `requirements.txt` / `pyproject.toml` | Python | `ruff check` | `pytest` |
| `go.mod` | Go | `go vet ./...` | `go test ./...` |
| `Cargo.toml` | Rust | `cargo clippy` | `cargo test` |
| `pom.xml` / `build.gradle` | Java | `mvn compile` | `mvn test` |

### 3단계: 지능형 하네스 초기화 실행
초기화 스크립트를 구동하여 Git Hook 연동 및 디렉토리 구조를 확보합니다.
```bash
# 쉘 스크립트 실행 권한 부여
chmod +x .agents/skills/init/init.sh .agents/skills/run-test/run-test.sh
chmod +x .agents/hooks/pre-commit.sh .agents/hooks/on-test-fail.sh .agents/hooks/post-task.sh

# 초기화 실행
./.agents/skills/init/init.sh
```

초기화 스크립트가 자동으로 수행하는 작업:
- `.tmp_artifacts/`, `docs/adr/`, `docs/failures/` 디렉토리 생성
- `.agents/hooks/pre-commit.sh` → `.git/hooks/pre-commit` 자동 복사 및 연동
- 기술 스택 자동 감지 후 `.agent.config.json.draft` 생성

### 4단계: agy 공식 플러그인 등록 (Plugin Activation)
하네스를 `agy` CLI에 정식 플러그인으로 등록하여 `/skill` 및 `/agents` 단축 커맨드를 네이티브하게 사용합니다.
```bash
agy plugin install .agents
```

> [!TIP]
> **지능형 스택 감지 및 동적 빌드**:
> 최초 세션 구동 시, 메인 에이전트는 기존 소스코드 설정(`package.json`, `requirements.txt` 등)을 스스로 자동 스캔하여 기술 스택을 완벽하게 분석합니다. 분석된 진단 리포트를 사용자에게 친절히 한국어로 보고하며 피드백 및 조율을 거친 뒤, 루트에 `.agent.config.json` 파일을 최적의 옵션으로 다이내믹하게 직접 자동 빌드하여 세팅을 완료합니다.

---

## 4. 에이전트 오케스트레이션 및 피드백 흐름 (Workflow)

```
[사용자 요청] -> [메인 에이전트(AGENTS.md) 작업 진행]
                     │
                     ▼
             [git commit 시도]
                     │
                     ▼ (Pre-commit Hook 자동 포착)
          [.agents/skills/run-test/run-test.sh 실행]
         ┌───────────┴───────────┐
         ▼ (성공)                ▼ (실패)
   [커밋 최종 승인]        [.agents/hooks/on-test-fail.sh 트리거]
                                 │
                                 ▼ (자동 피드백 루프)
                           [QA 서브 에이전트 기동] -> [에러 디버깅 분석 및 수정]
                                 │
                                 └-> [재시도 및 검증 반복 (최대 3회)]
```

---

## 5. 슬래시 단축 명령어 가이드 (Slash Commands)

에이전트 CLI 실행 중 대화창에서 아래의 슬래시(`/`) 커맨드를 입력하면, 에이전트의 일반 자연어 답변을 우회하여 **매핑된 하네스 백엔드 스크립트 실행 툴(`run_command`)을 자율적이고 즉각적으로 트리거**하여 실행합니다.

| 슬래시 명령어 | 실행 매핑 백엔드 명령어 | 동작 역할 |
| :--- | :--- | :--- |
| **`/init`** | `.agents/skills/init/init.sh` | 로컬 임시 디렉토리 및 Git 로컬 pre-commit 훅 자동 복사 및 동기화 |
| **`/test`** | `.agents/skills/run-test/run-test.sh` | `.agent.config.json` 설정을 읽어 린트 및 기능 테스트를 즉시 일괄 수행 및 보고 |
| **`/clean`** | `.agents/hooks/post-task.sh` | 빌드 시 생성된 `.tmp_artifacts/` 하위의 가비지 캐시 및 임시 로그 아티팩트 청소 |

---

## 6. 커스터마이징 가이드 (Customization)

* **의사결정 보강 (ADR 추가)**:
  * 기술적 전환점이나 규칙 변경 시 `docs/adr/` 하위에 ADR 명세서를 추가해두면, 에이전트가 임의로 구조를 해치는 대안을 제시하지 않고 시스템 흐름을 유지합니다.
* **코딩 가이드 확장**:
  * `.agents/rules/guidelines.rule.md`를 편집하여 프로젝트 고유의 컨벤션(예: "모든 함수 상단에는 한글로 목적 주석 작성")을 에이전트에게 강력하게 강제 적용할 수 있습니다.
* **새 서브 에이전트 추가**:
  * `.agents/agents/` 하위에 새 폴더를 만들고 `agent.json`을 작성하면 즉시 새로운 전문 서브 에이전트로 등록됩니다.
  * `AGENTS.md`의 서브 에이전트 목록에도 함께 추가하십시오.

---

## 7. 서브모듈 업데이트 (Submodule Update)

하네스 리포지토리에 업데이트가 발생했을 때, 연동 프로젝트에서 다음 명령어로 최신 버전을 반영합니다.
```bash
git submodule update --remote --merge .agents
```

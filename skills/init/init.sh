#!/bin/bash

# 한국어 주석: 고도화된 에이전트 하네스 초기화 스크립트입니다.
# 1. 임시 아티팩트 디렉토리 생성 (.tmp_artifacts)
# 2. 지식 저장소 디렉토리 생성 (docs/adr, docs/failures)
# 3. Git .git/hooks/pre-commit 자동 연동 및 린터 검증 강제화
# 4. .gitignore 자동 수정

set -e

# 한국어 주석: 하네스가 서브모듈로 마운트되어 실행 중인지, 혹은 하네스 자체 루트에서 로컬 기동 중인지 자동 판별하여 PROJECT_ROOT를 설정합니다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${SCRIPT_DIR}" == *"/.agents/skills/init" ]]; then
  # 서브모듈 마운트 실행 시: 3단계 상위가 실제 타겟 프로젝트 루트입니다.
  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
else
  # 하네스 자체 로컬 실행 시: 2단계 상위가 루트입니다.
  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

# 한국어 주석: 타겟 프로젝트 서브모듈(submodule) 경로와 하네스 자체 로컬 개발 경로를 동적으로 자동 감지하여 AGENT_DIR를 설정합니다.
if [ -d "${PROJECT_ROOT}/.agents" ]; then
  AGENT_DIR="${PROJECT_ROOT}/.agents"
else
  AGENT_DIR="${PROJECT_ROOT}"
fi

echo "============================================="
echo "Antigravity 에이전트 하네스 고도화 초기화를 시작합니다."
echo "============================================="

# 1. 임시 아티팩트 디렉토리 생성 (.tmp_artifacts)
TMP_DIR="${PROJECT_ROOT}/.tmp_artifacts"
if [ ! -d "${TMP_DIR}" ]; then
  mkdir -p "${TMP_DIR}"
  echo "[+] 임시 디렉토리 생성 완료: .tmp_artifacts"
else
  echo "[~] 임시 디렉토리 이미 존재함: .tmp_artifacts"
fi

# 2. 로그 디렉토리 생성
LOGS_DIR="${AGENT_DIR}/logs"
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir -p "${LOGS_DIR}"
  echo "[+] 로그 디렉토리 생성 완료: .agents/logs"
else
  echo "[~] 로그 디렉토리 이미 존재함: .agents/logs"
fi

# 3. 5대 지식 저장소 폴더 구조 자동 빌드 및 안내 가이드(README) 작성
ADR_DIR="${PROJECT_ROOT}/docs/adr"
FAILURES_DIR="${PROJECT_ROOT}/docs/failures"
DESIGN_DIR="${PROJECT_ROOT}/docs/system_design"
REFACTOR_DIR="${PROJECT_ROOT}/docs/refactoring"
SECURITY_DIR="${PROJECT_ROOT}/docs/security"
TEST_DIR="${PROJECT_ROOT}/docs/testing"

# (1) ADR 디렉토리 및 가이드 생성
if [ ! -d "${ADR_DIR}" ]; then
  mkdir -p "${ADR_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/adr"
fi
if [ ! -f "${ADR_DIR}/README.md" ]; then
  cat <<'EOF' > "${ADR_DIR}/README.md"
# Architecture Decision Records (ADR)

이 디렉토리는 프로젝트의 중요한 기술적 및 아키텍처적 의사결정 역사를 영구적으로 기록하는 저장소입니다.

## ✍️ 작성 규칙
* **의사결정의 배경과 맥락**: 새로운 라이브러리 도입, 설계 구조 변경, 통신 프레임워크 결정 등의 이유를 작성합니다.
* **트레이드오프 기재**: 선택한 설계의 장점과 함께 포기해야 했던 단점들을 함께 명시합니다.
* **파일 이름**: 순번 형식의 파일 이름(예: `0001-setup-framework.md`)을 사용하여 히스토리를 정렬합니다.
EOF
  echo "[+] ADR 가이드 README 생성 완료: docs/adr/README.md"
fi

# (2) Failures 디렉토리 및 가이드 생성
if [ ! -d "${FAILURES_DIR}" ]; then
  mkdir -p "${FAILURES_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/failures"
fi
if [ ! -f "${FAILURES_DIR}/README.md" ]; then
  cat <<'EOF' > "${FAILURES_DIR}/README.md"
# Failures Log (실패 경험 기록 저장소)

이 디렉토리는 구현 및 운영 과정에서 겪은 아키텍처적 실패, 까다로운 컴파일/빌드 에러, 혹은 서드파티 장애 극복 경험을 기록하는 지식 저장소입니다.

## ✍️ 작성 규칙
* **실패 상황**: 구체적으로 어떤 비정상적인 버그나 에러가 일어났는지 에러 로그를 포함하여 작성합니다.
* **원인 분석**: 해당 장애나 오류가 발생한 근본적인 원인을 설명합니다.
* **극복 및 우회책(Workaround)**: 임시 혹은 영구적으로 어떻게 문제를 해결하고 우회 설계를 도입했는지 정리하여, 다른 에이전트들이 같은 실수를 반복하지 않도록 가이드라인을 제시합니다.
EOF
  echo "[+] Failures 가이드 README 생성 완료: docs/failures/README.md"
fi

# (3) System Design 디렉토리 및 가이드 생성
if [ ! -d "${DESIGN_DIR}" ]; then
  mkdir -p "${DESIGN_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/system_design"
fi
if [ ! -f "${DESIGN_DIR}/README.md" ]; then
  cat <<'EOF' > "${DESIGN_DIR}/README.md"
# System Design & WBS (시스템 아키텍처 설계 및 태스크 보관소)

이 디렉토리는 사용자의 고차원적 기획 요구사항을 바탕으로 `system_architect` 에이전트가 직접 분석하고 쪼갠 시스템 설계서와 마이크로 태스크 목록(WBS)을 보존하는 지식 저장소입니다.

## ✍️ 작성 규칙
* **요구사항 분석**: 비즈니스 가치와 기술적 실현 가능성 및 비기능 요구조건을 분석하여 기록합니다.
* **상세 WBS 명세**: 독립적으로 실행할 수 있는 마이크로 개발 태스크 목록을 생성하고 적합한 개발 에이전트를 매핑합니다.
* **파일 이름**: 순번 형식의 파일 이름(예: `0001-neo4j-source-parsing.md`)을 사용합니다.
EOF
  echo "[+] System Design 가이드 README 생성 완료: docs/system_design/README.md"
fi

# (4) Refactoring 디렉토리 및 가이드 생성
if [ ! -d "${REFACTOR_DIR}" ]; then
  mkdir -p "${REFACTOR_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/refactoring"
fi
if [ ! -f "${REFACTOR_DIR}/README.md" ]; then
  cat <<'EOF' > "${REFACTOR_DIR}/README.md"
# Refactoring Design (아키텍처 개선 및 의존성 설계 보관소)

이 디렉토리는 `architecture_analyst` (AA) 에이전트가 기존 코드베이스의 순환 참조, 강한 결합도, 아키텍처 레이어 위반 사항을 진단하여 도출한 리팩토링 및 의존성 역전(DIP) 설계도 문서를 보존하는 지식 저장소입니다.

## ✍️ 작성 규칙
* **의존성 결함 진단**: 클래스 간 강한 결합이 유발된 원인과 해결 목표를 작성합니다.
* **의존성 역전(DIP) 설계**: 구체적인 추상 클래스/인터페이스 모듈 구성 계획과 설계도를 명시합니다.
* **파일 이름**: 순번 형식의 파일 이름(예: `0001-decouple-user-module.md`)을 사용합니다.
EOF
  echo "[+] Refactoring 가이드 README 생성 완료: docs/refactoring/README.md"
fi

# (5) Security 디렉토리 및 가이드 생성
if [ ! -d "${SECURITY_DIR}" ]; then
  mkdir -p "${SECURITY_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/security"
fi
if [ ! -f "${SECURITY_DIR}/README.md" ]; then
  cat <<'EOF' > "${SECURITY_DIR}/README.md"
# Security & Linter Audit Reports (보안 취약점 및 린트 감사 보고서 보관소)

이 디렉토리는 `security_auditor` 에이전트가 코드 정적 검사를 통해 발견한 민감 개인정보/API Key 노출 위험, 심각한 보안 취약점, 그리고 핵심 린트 규칙 위반 내역과 구체적인 해결 방안 보고서를 보존하는 지식 저장소입니다.

## ✍️ 작성 규칙
* **취약 구간 명세**: 발견된 파일 경로와 라인 번호, 위험 등급(High/Medium/Low)을 정확히 기재합니다.
* **조치 및 해결 가이드**: 개발자가 즉시 취약점을 교조할 수 있도록 구체적인 우회/패치 방안을 상세히 작성합니다.
* **파일 이름**: 순번 형식의 파일 이름(예: `0001-credential-exposure-prevention.md`)을 사용합니다.
EOF
  echo "[+] Security 가이드 README 생성 완료: docs/security/README.md"
fi

# (6) Testing 디렉토리 및 가이드 생성
if [ ! -d "${TEST_DIR}" ]; then
  mkdir -p "${TEST_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/testing"
fi
if [ ! -f "${TEST_DIR}/README.md" ]; then
  cat <<'EOF' > "${TEST_DIR}/README.md"
# QA Testing & Debugging Logs (테스트 검증 및 디버깅 보고서 보관소)

이 디렉토리는 `qa_engineer` 에이전트가 빌드 또는 기동 테스트 실패 시 에러 로그를 분석하고 조치 가이드를 수행한 결함 진단서 및 QA 테스트 결과 보고서를 보존하는 지식 저장소입니다.

## ✍️ 작성 규칙
* **결함 실패 분석**: 구체적인 오류 증상, 에러 덤프 로그 및 발생한 근본 원인을 작성합니다.
* **디버깅 조치 이력**: 코드 내 해결을 위해 수정한 타겟 라인과 환경 복구 가이드를 자세히 작성합니다.
* **파일 이름**: 순번 형식의 파일 이름(예: `0001-smoke-test-failure-handling.md`)을 사용합니다.
EOF
  echo "[+] Testing 가이드 README 생성 완료: docs/testing/README.md"
fi

# 4. Git Pre-commit Hook 자동 연동
GIT_DIR="${PROJECT_ROOT}/.git"
if [ -d "${GIT_DIR}" ]; then
  HOOKS_DIR="${GIT_DIR}/hooks"
  mkdir -p "${HOOKS_DIR}"

  # 하네스의 pre-commit.sh를 Git hooks로 복사 및 이름 변경
  cp "${AGENT_DIR}/hooks/pre-commit.sh" "${HOOKS_DIR}/pre-commit"
  chmod +x "${HOOKS_DIR}/pre-commit"
  echo "[+] Git hooks에 pre-commit 사전 검증 연동이 자동 완료되었습니다."
else
  echo "[!] 경고: .git 디렉토리를 찾을 수 없어 Git Hook 등록을 생략합니다. (git init을 먼저 수행해야 합니다.)"
fi

# 5. .gitignore에 임시 폴더 등록 여부 확인 및 추가
GITIGNORE_FILE="${PROJECT_ROOT}/.gitignore"
if [ ! -f "${GITIGNORE_FILE}" ]; then
  touch "${GITIGNORE_FILE}"
  echo "[+] .gitignore 파일을 새로 생성했습니다."
fi

ADDED_RULES=0
if ! grep -q "^.tmp_artifacts/$" "${GITIGNORE_FILE}"; then
  echo -e "\n# 에이전트 하네스 임시 결과물\n.tmp_artifacts/" >> "${GITIGNORE_FILE}"
  ADDED_RULES=1
fi
if ! grep -q "^.agents/logs/$" "${GITIGNORE_FILE}"; then
  echo ".agents/logs/" >> "${GITIGNORE_FILE}"
  ADDED_RULES=1
fi

if [ "$ADDED_RULES" -eq 1 ]; then
  echo "[+] .gitignore에 하네스 무시 규칙이 성공적으로 추가/보완되었습니다."
else
  echo "[~] .gitignore에 이미 관련 무시 규칙이 모두 등록되어 있습니다."
fi

# 6. 기술 스택 자동 감지 및 설정 드래프트 생성
echo "============================================="
echo "[+] 프로젝트 기술 스택 스캔을 시작합니다..."
echo "============================================="

DETECTED_TYPE="unknown"
LINT_CMD="mock-lint"
TEST_CMD="mock-test"
SRC_DIR="./src"

if [ -f "${PROJECT_ROOT}/package.json" ]; then
  DETECTED_TYPE="nodejs"
  LINT_CMD="npm run lint"
  TEST_CMD="npm test"
  SRC_DIR="./src"
elif [ -f "${PROJECT_ROOT}/requirements.txt" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ] || [ -f "${PROJECT_ROOT}/Pipfile" ]; then
  DETECTED_TYPE="python"
  LINT_CMD="ruff check"
  TEST_CMD="pytest"
  SRC_DIR="."
elif [ -f "${PROJECT_ROOT}/go.mod" ]; then
  DETECTED_TYPE="go"
  LINT_CMD="go vet ./..."
  TEST_CMD="go test ./..."
  SRC_DIR="."
elif [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
  DETECTED_TYPE="rust"
  LINT_CMD="cargo clippy"
  TEST_CMD="cargo test"
  SRC_DIR="./src"
elif [ -f "${PROJECT_ROOT}/pom.xml" ] || [ -f "${PROJECT_ROOT}/build.gradle" ]; then
  DETECTED_TYPE="java"
  LINT_CMD="mvn compile"
  if [ -f "${PROJECT_ROOT}/build.gradle" ]; then
    TEST_CMD="./gradlew test"
  else
    TEST_CMD="mvn test"
  fi
  SRC_DIR="./src"
fi

if [ "${DETECTED_TYPE}" != "unknown" ]; then
  echo "[+] 감지된 기술 스택: ${DETECTED_TYPE}"
  echo "[+] 제안된 린트 명령어: ${LINT_CMD}"
  echo "[+] 제안된 테스트 명령어: ${TEST_CMD}"
else
  echo "[!] 감지된 기술 스택이 없으므로 기본(nodejs-example) 모의 설정을 제안합니다."
  DETECTED_TYPE="nodejs-example"
  LINT_CMD="npm run lint"
  TEST_CMD="npm test"
fi

# 드래프트 JSON 파일 경로 정의 및 공식 실 설정 파일 정의
DRAFT_FILE="${PROJECT_ROOT}/.agent.config.json.draft"
FINAL_FILE="${PROJECT_ROOT}/.agent.config.json"

# 드래프트 파일 작성 (한국어 주석 포함)
cat <<EOF > "${DRAFT_FILE}"
{
  "project_type": "${DETECTED_TYPE}",
  "lint_command": "${LINT_CMD}",
  "test_command": "${TEST_CMD}",
  "src_directory": "${SRC_DIR}",
  "telemetry": {
    "enabled": false
  }
}
EOF

echo "[+] 프로젝트 기술 스택 분석을 거쳐 임시 설정 파일이 정상 생성되었습니다: .agent.config.json.draft"

# 한국어 주석: 공식 설정 파일(.agent.config.json)이 프로젝트 루트에 존재하지 않는 신규 수립 환경인 경우, 드래프트를 즉시 공식 설정으로 승격 적용하고 잔재는 소거합니다.
if [ ! -f "${FINAL_FILE}" ]; then
  mv "${DRAFT_FILE}" "${FINAL_FILE}"
  echo "[+] 신규 공식 설정 파일이 성공적으로 수립 및 자동 승격되었습니다: .agent.config.json"
else
  # 한국어 주석: 기존 공식 설정이 이미 존재하는 경우, 기존 설정을 안전히 보존하고 임시 생성되었던 드래프트 찌꺼기는 즉각 영구 소거(rm)합니다.
  rm -f "${DRAFT_FILE}"
  echo "[~] 프로젝트 루트에 기존 .agent.config.json이 이미 존재하여 기존 설정을 보존하고 드래프트 가비지는 깨끗이 소거했습니다."
fi

echo "============================================="
echo "하네스 고도화 초기화가 성공적으로 끝났습니다!"
echo "============================================="
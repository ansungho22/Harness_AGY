#!/bin/bash

# 한국어 주석: 고도화된 에이전트 하네스 초기화 스크립트입니다.
# 1. 임시 아티팩트 디렉토리 생성 (.tmp_artifacts)
# 2. 지식 저장소 디렉토리 생성 (docs/adr, docs/failures)
# 3. Git .git/hooks/pre-commit 자동 연동 및 린터 검증 강제화
# 4. .gitignore 자동 수정

set -e

# 프로젝트 루트 디렉토리 정의
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT_DIR="${PROJECT_ROOT}/.agents"

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

# 3. 지식 저장소 폴더 구조 자동 빌드 (docs/adr, docs/failures)
ADR_DIR="${PROJECT_ROOT}/docs/adr"
FAILURES_DIR="${PROJECT_ROOT}/docs/failures"

if [ ! -d "${ADR_DIR}" ]; then
  mkdir -p "${ADR_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/adr"
fi

# 한국어 주석: ADR 디렉토리 가이드용 README.md 파일이 존재하지 않는 경우 자동으로 작성합니다.
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

if [ ! -d "${FAILURES_DIR}" ]; then
  mkdir -p "${FAILURES_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/failures"
fi

# 한국어 주석: Failures 디렉토리 가이드용 README.md 파일이 존재하지 않는 경우 자동으로 작성합니다.
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
if [ -f "${GITIGNORE_FILE}" ]; then
  if ! grep -q ".tmp_artifacts" "${GITIGNORE_FILE}"; then
    echo -e "\n# 에이전트 하네스 임시 결과물\n.tmp_artifacts/\n.agents/logs/" >> "${GITIGNORE_FILE}"
    echo "[+] .gitignore에 하네스 무시 규칙이 추가되었습니다."
  else
    echo "[~] .gitignore에 이미 관련 규칙이 등록되어 있습니다."
  fi
else
  echo -e "# 에이전트 하네스 임시 결과물\n.tmp_artifacts/\n.agents/logs/" > "${GITIGNORE_FILE}"
  echo "[+] .gitignore 파일을 새로 생성하고 규칙을 기록했습니다."
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

# 드래프트 JSON 파일 경로 정의
DRAFT_FILE="${PROJECT_ROOT}/.agent.config.json.draft"

if [ -f "${PROJECT_ROOT}/.agent.config.json" ]; then
  echo "[~] 기존 .agent.config.json 파일이 이미 존재합니다. 안전을 위해 덮어쓰지 않고 드래프트 파일만 생성합니다."
fi

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

echo "[+] 기술 스택 분석 결과를 담은 드래프트 설정 파일이 생성되었습니다: .agent.config.json.draft"
echo "============================================="
echo "하네스 고도화 초기화가 성공적으로 끝났습니다!"
echo "============================================="


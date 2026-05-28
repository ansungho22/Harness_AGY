#!/bin/bash

# 한국어 주석: 고도화된 에이전트 하네스 초기화 스크립트입니다.
# 1. 임시 아티팩트 디렉토리 생성 (.tmp_artifacts)
# 2. 지식 저장소 디렉토리 생성 (docs/adr, docs/failures)
# 3. Git .git/hooks/pre-commit 자동 연동 및 린터 검증 강제화
# 4. .gitignore 자동 수정

set -e

# 프로젝트 루트 디렉토리 정의
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT_DIR="${PROJECT_ROOT}/.agent"

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
  echo "[+] 로그 디렉토리 생성 완료: .agent/logs"
else
  echo "[~] 로그 디렉토리 이미 존재함: .agent/logs"
fi

# 3. 지식 저장소 폴더 구조 자동 빌드 (docs/adr, docs/failures)
ADR_DIR="${PROJECT_ROOT}/docs/adr"
FAILURES_DIR="${PROJECT_ROOT}/docs/failures"

if [ ! -d "${ADR_DIR}" ]; then
  mkdir -p "${ADR_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/adr"
fi

if [ ! -d "${FAILURES_DIR}" ]; then
  mkdir -p "${FAILURES_DIR}"
  echo "[+] 지식 저장소 디렉토리 생성 완료: docs/failures"
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
    echo -e "\n# 에이전트 하네스 임시 결과물\n.tmp_artifacts/\n.agent/logs/" >> "${GITIGNORE_FILE}"
    echo "[+] .gitignore에 하네스 무시 규칙이 추가되었습니다."
  else
    echo "[~] .gitignore에 이미 관련 규칙이 등록되어 있습니다."
  fi
else
  echo -e "# 에이전트 하네스 임시 결과물\n.tmp_artifacts/\n.agent/logs/" > "${GITIGNORE_FILE}"
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


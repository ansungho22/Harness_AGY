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

echo "============================================="
echo "하네스 고도화 초기화가 성공적으로 끝났습니다!"
echo "============================================="

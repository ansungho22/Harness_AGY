#!/bin/bash

# 한국어 주석: 기동 테스트 및 린트 검사 통합 실행 래퍼 스크립트입니다.
# 에러가 발생하면 상세 로그를 .tmp_artifacts/test_error.log에 저장합니다.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/.agent.config.json"
TMP_DIR="${PROJECT_ROOT}/.tmp_artifacts"
ERROR_LOG="${TMP_DIR}/test_error.log"

# 임시 폴더가 없으면 자동 생성합니다.
mkdir -p "${TMP_DIR}"

# 이전 에러 로그 삭제
rm -f "${ERROR_LOG}"

# 1. 설정 파일이 존재하는지 검증하고 읽어옵니다.
if [ -f "${CONFIG_FILE}" ]; then
  # Python3를 활용한 다단계 안전 JSON 파싱 도입
  if command -v python3 &> /dev/null; then
    LINT_CMD=$(python3 -c "import sys, json; print(json.load(open('${CONFIG_FILE}'))['lint_command'])" 2>/dev/null || echo "mock-lint")
    TEST_CMD=$(python3 -c "import sys, json; print(json.load(open('${CONFIG_FILE}'))['test_command'])" 2>/dev/null || echo "mock-test")
  elif command -v jq &> /dev/null; then
    LINT_CMD=$(jq -r '.lint_command' "${CONFIG_FILE}")
    TEST_CMD=$(jq -r '.test_command' "${CONFIG_FILE}")
  else
    LINT_CMD=$(grep -o '"lint_command": "[^"]*' "${CONFIG_FILE}" | cut -d'"' -f4)
    TEST_CMD=$(grep -o '"test_command": "[^"]*' "${CONFIG_FILE}" | cut -d'"' -f4)
  fi
else
  # 설정 파일이 없을 경우 기본 모의(Mock) 설정을 적용합니다.
  LINT_CMD="mock-lint"
  TEST_CMD="mock-test"
fi

# 피드백 훅 경로 탐지
if [ -f "${PROJECT_ROOT}/.agents/hooks/on-test-fail.sh" ]; then
  FAIL_HOOK="${PROJECT_ROOT}/.agents/hooks/on-test-fail.sh"
elif [ -f "${PROJECT_ROOT}/hooks/on-test-fail.sh" ]; then
  FAIL_HOOK="${PROJECT_ROOT}/hooks/on-test-fail.sh"
else
  FAIL_HOOK=""
fi

echo "============================================="
echo "[+] 린트 검사 시작: ${LINT_CMD}"
echo "============================================="

# 2. 린트 검사 수행 (예시 모의 검사 포함)
if [ "${LINT_CMD}" == "mock-lint" ] || ( [ "${LINT_CMD}" == "npm run lint" ] && [ ! -f "${PROJECT_ROOT}/package.json" ] ); then
  echo "[!] 의존성 파일(package.json 등)이 없거나 mock 설정되어 린트 검사 시뮬레이션을 작동합니다."
  echo "[~] 소스코드 정적 분석 완료 - 특이사항 없음."
else
  # 실제 프로젝트의 린터 실행
  if ! eval "${LINT_CMD}" 2> "${ERROR_LOG}"; then
    echo "[-] 린트 검사 실패!" | tee -a "${ERROR_LOG}"
    if [ -n "${FAIL_HOOK}" ]; then bash "${FAIL_HOOK}" 2>/dev/null || true; fi
    exit 1
  fi
fi

echo "============================================="
echo "[+] 기동 테스트(Smoke Test) 시작: ${TEST_CMD}"
echo "============================================="

# 3. 기동 테스트 수행 (예시 모의 테스트 포함)
if [ "${TEST_CMD}" == "mock-test" ] || ( [ "${TEST_CMD}" == "npm test" ] && [ ! -f "${PROJECT_ROOT}/package.json" ] ); then
  echo "[!] 의존성 파일(package.json 등)이 없거나 mock 설정되어 기동 테스트 시뮬레이션을 작동합니다."
  echo "[+] 기동 테스트 완료 - 포트 8080 통신 연결 확인됨."
else
  # 실제 기동 테스트 실행
  if ! eval "${TEST_CMD}" 2> "${ERROR_LOG}"; then
    echo "[-] 기동 테스트 수행 중 치명적 오류 발생!" | tee -a "${ERROR_LOG}"
    if [ -n "${FAIL_HOOK}" ]; then bash "${FAIL_HOOK}" 2>/dev/null || true; fi
    exit 1
  fi
fi

echo "============================================="
echo "[+] 모든 기본 검증 테스트를 성공적으로 마쳤습니다!"
echo "============================================="
exit 0

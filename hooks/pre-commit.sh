#!/bin/bash

# 한국어 주석: Git 커밋 직전에 자동으로 실행되는 Pre-commit 훅 스크립트입니다.
# 코드 검증이 완전히 통과되지 않은 불안정한 상태에서는 커밋을 원천 봉쇄합니다.

# 한국어 주석: 실행 중인 디렉토리 또는 Git 최상위 루트 디렉토리를 탐색하여 설정합니다.
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

# 한국어 주석: 타겟 프로젝트 서브모듈(submodule) 경로와 하네스 자체 로컬 경로를 동적으로 자동 감지합니다.
SUBMODULE_RUNNER="${PROJECT_ROOT}/.agents/skills/run-test/run-test.sh"
LOCAL_RUNNER="${PROJECT_ROOT}/skills/run-test/run-test.sh"

if [ -f "${SUBMODULE_RUNNER}" ]; then
  TEST_RUNNER="${SUBMODULE_RUNNER}"
elif [ -f "${LOCAL_RUNNER}" ]; then
  TEST_RUNNER="${LOCAL_RUNNER}"
else
  TEST_RUNNER=""
fi

echo "============================================="
echo "[+] Git Commit 사전 검증 시작 (Pre-commit)"
echo "============================================="

# 1. 테스트 실행 스크립트가 존재하는지 확인
if [ -f "${TEST_RUNNER}" ]; then
  # 린트 및 기동 테스트 통합 래퍼 실행
  if ! bash "${TEST_RUNNER}"; then
    echo "---------------------------------------------"
    echo "[!] 에러: 린트 검사 또는 기동 테스트가 실패했습니다!"
    echo "[!] 코드를 올바르게 수정하기 전에는 커밋할 수 없습니다."
    echo "============================================="
    exit 1
  fi
else
  echo "[!] 경고: 테스트 실행기(${TEST_RUNNER})를 찾을 수 없습니다. 검사를 생략합니다."
fi

echo "============================================="
echo "[+] 사전 검증 통과! 커밋을 계속 진행합니다."
echo "============================================="
exit 0

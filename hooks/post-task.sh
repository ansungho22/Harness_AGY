#!/bin/bash

# 한국어 주석: 에이전트 하네스 작업 종료 후 실행되는 가비지 컬렉션(GC) 훅 스크립트입니다.
# 에이전트가 작업 중 발생시킨 임시 파일 및 로그를 말끔히 비워냅니다.

# 한국어 주석: 실행 중인 디렉토리 또는 Git 최상위 루트 디렉토리를 탐색하여 설정합니다.
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi
TMP_DIR="${PROJECT_ROOT}/.tmp_artifacts"

echo "============================================="
echo "[+] 에이전트 작업 종료: 가비지 컬렉션 수행 중..."
echo "============================================="

# 1. 임시 아티팩트 및 로그 비우기
if [ -d "${TMP_DIR}" ]; then
  # 디렉토리 자체는 유지하되 내부 파일만 깨끗하게 비웁니다.
  find "${TMP_DIR}" -mindepth 1 -delete
  echo "[+] 임시 디렉토리(.tmp_artifacts) 내 파일 정리 완료."
else
  echo "[~] 정리할 임시 디렉토리가 존재하지 않습니다."
fi

echo "============================================="
echo "[+] 가비지 컬렉션 처리가 안전하게 끝났습니다."
echo "============================================="

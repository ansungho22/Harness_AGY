---
name: init
description: Initializes the workspace environment for the multi-agent harness.
version: 1.0.0
---

## Goal
워크스페이스 초기에 필요한 폴더 구조, git hooks, 그리고 임시 디렉토리를 설정하여 에이전트들의 작업 환경을 구성합니다.

## Activation Triggers
- 사용자가 초기 셋업을 요청할 때 ("/init")
- 프로젝트에 처음 에이전트 플러그인이 로드되고 구동 환경이 잡히지 않았을 때

## Execution Protocol
1. `.agents/skills/init/init.sh` 쉘 스크립트를 실행하여 다음 작업을 수행합니다.
   - `.tmp_artifacts`, `docs/adr`, `docs/failures` 등 필요한 디렉토리 생성
   - `.agents/hooks/pre-commit.sh` 파일을 워크스페이스의 `.git/hooks/pre-commit`으로 복사
   - 프로젝트 스택에 맞춰 `.agent.config.json.draft` 생성
2. 스크립트 실행 후 출력 결과를 분석하여 워크스페이스 구조가 올바르게 준비되었는지 확인합니다.

## Constraints
- 프로젝트에 이미 존재하는 데이터를 함부로 덮어쓰거나 삭제하지 마십시오.
- git hook 설정 시 실행 권한(chmod +x)을 올바르게 부여해야 합니다.

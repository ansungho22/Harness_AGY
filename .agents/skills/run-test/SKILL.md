---
name: run-test
description: Triggers workspace test suites (pytest, jest, etc.) and captures execution results.
version: 1.0.0
---

## Goal
현재 워크스페이스의 기술 스택을 자동으로 감지하고, 그에 맞는 테스트 커맨드를 실행하여 결과를 반환합니다.

## Activation Triggers
- 사용자가 테스트 실행을 명시적으로 요청할 때 ("테스트 돌려줘", "버그 있는지 검사해줘")
- `qa_engineer` 에이전트가 코드를 검증해야 할 때
- `hooks/pre-commit.sh` 시점에서 검증이 필요할 때

## Execution Protocol
1. 프로젝트 루트에서 `package.json` 또는 `requirements.txt` / `pyproject.toml`을 확인합니다.
   - Node.js 프로젝트인 경우: `npm test` 또는 `yarn test` 실행
   - Python 프로젝트인 경우: `pytest` 실행
2. 만약 특정 테스트 스크립트 실행이 복잡하다면, 같은 디렉터리에 동봉된 실행 파일(`.agents/skills/run-test/run-test.sh`)을 터미널에서 실행하십시오.
3. 테스트가 실패(Exit Code가 0이 아님)하면, 에러 로그의 Stack Trace를 파싱하여 요약본을 출력하십시오.

## Constraints
- 테스트 환경에 데이터베이스 등 환경 변수가 필요한 경우, `.env` 파일을 먼저 읽고 필요한 값이 누락되었는지 검사하십시오.
- `rm -rf` 등 테스트 디렉터리 외의 파일을 파괴하는 명령어는 절대 수행하지 마십시오.

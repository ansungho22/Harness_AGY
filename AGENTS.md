# AGENTS.md - 에이전트 개발 및 검증 규칙 가이드

본 문서는 AI 에이전트가 이 프로젝트 내에서 작업을 수행할 때 반드시 지켜야 할 **최상위 지침서**입니다. 작업을 시작하기 전 본 문서와 연동 문서들을 필독하십시오.

---

## 1. 아키텍처 제약 및 자동 강제화 (Framework Constraints)
이 프로젝트는 단순한 텍스트 가이드에 의존하지 않고, 물리적 도구(Linter 및 Test)로 코드를 제약합니다.

1. **정적 분석 및 린트 강제**:
   * 모든 수정 사항은 설정된 린터(`.agent.config.json` 내 `lint_command`)의 규칙을 무조건 통과해야 합니다.
2. **Git Commit 차단 (Pre-commit Hook)**:
   * 코드가 커밋되기 직전 `.agent/hooks/pre-commit.sh`가 구동되어 린트 및 기동 테스트를 자동 실행합니다. 실패 시 커밋이 즉시 차단되므로 완성되지 않은 불완전한 코드는 커밋하지 마십시오.
3. **레이어 위반 금지**:
   * 아키텍처 제약 규칙([architecture.rule.md](file:///Users/horange/Code/Harness/.agent/rules/architecture.rule.md))을 준수하며, 특히 도메인 레이어에서 외부 인프라스트럭처 레이어를 직접 참조(Import)하는 행위를 엄격히 금지합니다.

---

## 2. 작업 전 지식 저장소 참고 (Required Knowledge Bases)
세션 시작 시 과거의 기술적 의사결정 맥락을 존중하기 위해 다음 문서를 반드시 탐색하십시오.

* **기술 결정 기록 (Architecture Decision Records - ADR)**: [docs/adr/](file:///Users/horange/Code/Harness/docs/adr/)
  * 새로운 외부 라이브러리나 아키텍처 아웃라인을 도입하기 전, 이미 정의된 결정 기록(예: Redis나 ORM 사용 여부)이 있는지 확인하십시오. 엉뚱한 대안을 임의로 도입해서는 안 됩니다.
* **실패 경험 기록 (Failures Log)**: [docs/failures/](file:///Users/horange/Code/Harness/docs/failures/)
  * 이전에 도입하려다 실패했던 기록(예: 동기식 API 직접 호출의 레이턴시 이슈 등)을 확인하여 동일한 실수를 반복하지 마십시오.
* **코딩 가이드라인**: [.agent/rules/guidelines.rule.md](file:///Users/horange/Code/Harness/.agent/rules/guidelines.rule.md)
  * 모든 소스코드 주석은 **한국어**로만 작성해야 합니다.

---

## 3. 에러 처리 및 피드백 가이드
* 예외(Exception) 처리 시 무조건적인 `try-except pass`를 금지합니다.
* 에러가 발생한 지점에서 에이전트와 인간 개발자가 원인을 명확히 파악할 수 있도록 구체적인 예외 메시지(`ValueError`, `TypeError` 등)를 명시적으로 던져야 합니다.

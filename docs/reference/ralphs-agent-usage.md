# Ralph AGENTS.md Pattern

## Source

- https://github.com/snarktank/ralph
- https://ghuntley.com/ralph/

## Key claims

- 루프 기반 에이전트는 매 iteration마다 컨텍스트가 초기화되므로, AGENTS.md가 누적 메모리 역할을 한다.
- AGENTS.md에는 패턴, 주의점, 유용한 컨텍스트를 지속적으로 기록한다.

## Adopted

- AGENTS.md를 "누적 학습 메모리"로 쓰는 개념 자체는 참고한다.

## Not adopted

- 이 레포의 기본 워크플로우는 대화형 세션과 문서 기반 협업이므로, 루프 기반 AGENTS.md 운영을 기본 전략으로 채택하지 않는다.

## Notes

- 루프 기반 자동 실행이 도입되거나 컨텍스트가 매번 초기화되는 환경이면 재검토 가능하다.

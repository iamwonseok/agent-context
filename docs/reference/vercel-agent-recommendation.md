# Vercel AGENTS.md Guidance

## Source

- https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals

## Key claims

- AGENTS.md에 압축 인덱스를 넣는 방식이 skills 기반 호출보다 안정적으로 동작했다.
- "retrieval-led reasoning"을 명시하면 최신 문서를 먼저 참고하게 되어 정확도가 올라간다.
- 전체 문서를 넣기보다, 문서 위치를 알려주는 지도(map) 형식이 효율적이다.

## Adopted

- 상시 컨텍스트에 근거를 두고, 결정 지점을 줄이는 접근을 선호한다.
- 문서 요약은 "지도" 형태로 유지하고, 상세는 실제 문서를 읽도록 유도한다.

## Not adopted

- 별도의 AGENTS.md에 압축 인덱스를 상시 유지하는 방식은 이 레포의 기본 전략으로 채택하지 않는다.
- 대신 `.cursorrules`를 상시 컨텍스트로 사용하고, 필요할 때만 최소 요약을 추가한다.

## Notes

- 이 레포는 사용자용 문서와 에이전트용 컨텍스트를 구분한다.
- 문서 인덱스(map)는 사용자용 reference 문서에 포함하지 않는다.

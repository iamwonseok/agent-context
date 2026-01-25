# C Coding Convention Detectability Report

## Coverage Summary

| Metric | soc-vnv (External) | agent-context (Internal) |
|:-------|-------------------:|-------------------------:|
| **Total Rules** | 76 | 76 |
| **Detectable (Yes)** | 44 (58%) | - |
| **Detectable (No)** | 32 (42%) | - |
| **Actually Implemented** | N/A | **12** (16%) |
| - `lint-c` (regex-based) | - | 11 rules |
| - whitespace check | - | 1 rule |
| **AI Review (Optional)** | - | 19 rules |
| **Not Implemented** | - | 45 rules |

### agent-context `lint-c` 구현 현황

**직접 검사 (c_rules.sh)**: 11개 규칙
- C-01-01 (Tab 들여쓰기), C-01-02 (switch-case 정렬)
- C-01-11 (함수 중괄호), C-01-12 (제어문 중괄호), C-01-13 (else 위치)
- C-01-14 (중괄호 필수), C-01-15 (if 내 할당 금지), C-01-18 (포인터 위치)
- C-02-05 (do-while 매크로), C-02-08 (매크로 괄호), C-03-04 (snake_case)

**별도 스크립트**: whitespace check (C-01-05)

**AI Review (Ollama 필요)**: Detectable=No 규칙 중 19개 대상
- 의미론적 규칙: 네이밍 적절성, 단일 책임, 영어 사용 등

### Gap Analysis

| Category | soc-vnv 제안 도구 | agent-context 미구현 | 비고 |
|:---------|:------------------|:---------------------|:-----|
| Formatting | clang-format (22개) | **22개 미사용** | `.clang-format` 템플릿만 제공 |
| Static Analysis | clang-tidy (15개) | **15개 미사용** | `.clang-tidy` 템플릿만 제공 |
| Pre-commit | pre-commit hooks (2개) | **2개 미사용** | 템플릿만 제공 |
| Kernel Style | checkpatch (8개) | **미구현** | 미지원 |

---

## Detailed Rule Comparison

| ID | Rule Description | Detectable | soc-vnv (Tool) | agent-context (Actual) |
|:---|:---|:---:|:---|:---|
| **C-01-01** | 들여쓰기는 탭(Tab)을 사용하며, 탭의 크기는 4 공백(Space)으로 설정한다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-02** | switch 문에서는 case 레이블을 switch와 동일한 들여쓰기 레벨(column)에 위치시킨다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-03** | 한 줄에 여러 문장(Statement)을 넣지 않는다. | Yes | clang-format | - |
| **C-01-04** | 한 줄에 하나의 변수 선언을 원칙으로 하되, 포인터가 아닌 기본 자료형의 연관된 변수는 예외적으로 허용한다. | No | - | AI review (optional) |
| **C-01-05** | 줄의 끝(Trailing whitespace)에 공백 문자를 남기지 않는다. | Yes | clang-format / checkpatch | whitespace check (optional) |
| **C-01-06** | 파일의 마지막에 불필요한 빈 라인을 추가하지 않는다. | Yes | clang-format / end-of-file-fixer | - |
| **C-01-07** | 파일의 줄바꿈 형식은 Unix 스타일(LF)을 사용한다. | Yes | pre-commit (forbid-crlf) | - |
| **C-01-08** | 코드 한 줄은 최대 100자를 넘지 않도록 작성한다. | Yes | clang-format | - |
| **C-01-09** | 줄을 나눌 때 하위 항목은 상위 항목보다 짧게 작성하고, 오른쪽으로 들여쓰기하여 배치한다. | Yes | clang-format | - |
| **C-01-10** | 로그 메시지 등 출력을 위한 문자열 리터럴 자체는 줄을 나누지 않는다. | Yes | clang-format | - |
| **C-01-11** | 함수의 시작 중괄호({)는 함수 선언부의 다음 줄 시작 지점에 위치한다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-12** | 제어문(if, switch, for, while)의 시작 중괄호({)는 해당 선언부와 같은 줄에 위치한다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-13** | 닫는 중괄호(})와 이어지는 키워드(else, while)는 같은 줄에 위치한다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-14** | 조건문이나 루프의 본문이 한 줄이라도 반드시 중괄호를 사용한다. | Yes | clang-tidy / checkpatch | `lint-c` (regex) |
| **C-01-15** | if 조건식 내부에서 변수 할당(Assignment)을 수행하지 않는다. | Yes | clang-tidy / checkpatch | `lint-c` (regex) |
| **C-01-16** | 제어문 키워드(if, switch, for, while 등) 뒤에는 공백을 하나 추가한다. | Yes | clang-format | - |
| **C-01-17** | sizeof, typeof, alignof, __attribute__ 뒤에는 공백을 추가하지 않는다. | Yes | clang-format | - |
| **C-01-18** | 포인터 변수 선언 및 반환 타입 지정 시 * 기호는 변수명(또는 함수명) 쪽에 붙인다. | Yes | clang-format | `lint-c` (regex) |
| **C-01-19** | 이항 및 삼항 연산자의 양쪽에는 공백을 하나씩 추가한다. | Yes | clang-format | - |
| **C-01-20** | 단항 연산자(&, *, +, -, ~, !) 뒤에는 공백을 두지 않는다. | Yes | clang-format | - |
| **C-01-21** | 증감 연산자(++, --)와 피연산자 사이에는 공백을 두지 않는다. | Yes | clang-format | - |
| **C-01-22** | 구조체 멤버 접근 연산자(., ->) 앞뒤에는 공백을 두지 않는다. | Yes | clang-format | - |
| **C-01-23** | 매크로와 열거형 상수는 대문자를 사용한다. | Yes | clang-tidy / checkpatch | - |
| **C-01-24** | 표현식을 분할할 때는 연산자 위치를 일관성 있게(앞 또는 뒤) 맞춘다. | Yes | clang-format | - |
| **C-01-25** | 주석을 포함한 모든 코드 내 텍스트는 영어를 사용한다. | No | - | AI review (optional) |
| **C-01-26** | 코드는 그 자체로 설명되도록 작성하며, 불필요한 동작 설명 주석은 지양한다. | No | - | AI review (optional) |
| **C-01-27** | 헤더 파일에는 #pragma once 대신 표준 #define 가드를 사용한다. | Yes | clang-tidy / header-guard | - |
| **C-01-28** | 컴파일 타임 제약 조건 위반 시 #error 지시자를 사용하여 빌드를 중단한다. | No | - | - |
| **C-02-01** | 구조체와 포인터 정의에 typedef를 사용하여 타입을 숨기지 않는다. | No | - | AI review (optional) |
| **C-02-02** | 함수 종료 시 공통된 자원 해제(Cleanup)가 필요한 경우에만 goto문을 사용한다. | No | - | AI review (optional) |
| **C-02-03** | goto 레이블 이름은 해당 위치의 역할이나 이유를 명확히 기술한다. | No | - | AI review (optional) |
| **C-02-04** | 자원 해제가 필요 없는 단순 종료 시에는 goto 대신 직접 return한다. | No | - | AI review (optional) |
| **C-02-05** | 복수 문장으로 구성된 매크로는 do-while(0) 구문으로 감싸서 작성한다. | Yes | clang-tidy / checkpatch | `lint-c` (regex) |
| **C-02-06** | 호출부의 제어 흐름(return, goto 등)에 영향을 주는 매크로를 사용하지 않는다. | No | - | AI review (optional) |
| **C-02-07** | 매크로 내부에서 인자로 전달되지 않은 외부 변수를 참조하지 않는다. | No | - | AI review (optional) |
| **C-02-08** | 매크로 정의 시 모든 인자는 괄호()로 감싸서 연산자 우선순위 문제를 방지한다. | Yes | clang-tidy / checkpatch | `lint-c` (regex) |
| **C-02-09** | 매크로를 좌변 값(L-value)으로 사용하여 대입하지 않는다. | No | - | AI review (optional) |
| **C-02-11** | 메모리 할당 시 크기 지정은 sizeof(*pointer) 형식을 사용한다. | Yes | clang-tidy | - |
| **C-02-12** | 상수를 정의하는 매크로 표현식 전체를 괄호로 감싼다. | Yes | clang-tidy / checkpatch | - |
| **C-02-13** | 전처리 지시문은 1열에서 시작하며, #endif 뒤에는 주석으로 조건을 명시한다. | No | - | - |
| **C-02-14** | 상위 스코프 변수를 가리는(Shadowing) 지역 변수명을 사용하지 않는다. | Yes | clang-tidy | - |
| **C-02-15** | 기본 자료형 대신 <stdint.h>의 고정 폭 정수 타입을 사용한다. | No | - | - |
| **C-02-16** | 증감 연산자를 조건식이나 다른 연산 내부에 섞어 쓰지 않는다. | Yes | clang-tidy | - |
| **C-02-17** | 제약 조건 위반 시 #error를 사용하여 명시적으로 컴파일을 막는다. | No | - | - |
| **C-03-01** | 전역 변수와 함수 이름은 설명적으로 짓는다. | No | - | AI review (optional) |
| **C-03-02** | 지역 변수는 간결하게 짓되 관습적인 이름을 사용한다. | No | - | AI review (optional) |
| **C-03-03** | 모호한 약어 사용을 금지한다. | No | - | AI review (optional) |
| **C-03-04** | 식별자 단어 구분에는 밑줄(snake_case)을 사용한다. | Yes | clang-tidy / checkpatch | `lint-c` (regex) |
| **C-03-05** | 함수 및 변수 이름은 소문자를 사용한다. | Yes | clang-tidy / checkpatch | - |
| **C-03-06** | 헝가리안 표기법을 사용하지 않는다. | No | - | AI review (optional) |
| **C-03-07** | 모든 네이밍과 주석은 미국식 영어를 사용한다. | No | - | - |
| **C-03-08** | 변수명 작성 시 단수와 복수의 의미를 명확히 구분한다. | No | - | - |
| **C-03-09** | 식별자에 이중 밑줄(__)을 사용하지 않는다. | Yes | clang-tidy / checkpatch | - |
| **C-03-10** | 소스 및 헤더 파일의 이름은 snake_case를 따른다. | Yes | check-filename-lower-case | - |
| **C-04-01** | 함수는 한 가지 기능만 명확하게 수행하도록 작게 작성한다. | No | - | AI review (optional) |
| **C-04-02** | 함수의 매개변수 개수는 4개를 초과하지 않도록 설계한다. | Yes | clang-tidy | - |
| **C-04-03** | 함수 내부의 지역 변수 개수는 10개를 초과하지 않도록 한다. | Yes | clang-tidy | - |
| **C-04-04** | 함수 정의와 함수 정의 사이에는 빈 줄 하나를 둔다. | Yes | clang-format | - |
| **C-04-05** | 함수 프로토타입 선언 시 매개변수 변수명도 명시한다. | Yes | clang-tidy / checkpatch | - |
| **C-04-06** | Public 함수는 명확한 반환 값 규칙을 따른다. | No | - | AI review (optional) |
| **C-04-07** | 동작 수행 함수는 에러 코드를 반환한다. (0: 성공, <0: 실패) | No | - | AI review (optional) |
| **C-04-08** | 상태 확인 함수는 bool형을 반환한다. | No | - | AI review (optional) |
| **C-04-09** | 표준 매크로나 라이브러리 함수를 재구현하지 않는다. | No | - | AI review (optional) |
| **C-04-10** | 함수 원형은 헤더에 선언하고, 소스 내 extern 선언을 금지한다. | Yes | clang-tidy | - |
| **C-04-11** | 전역 변수를 소스 내에서 extern으로 직접 선언하지 않는다. | No | - | - |
| **C-05-01** | int, long 대신 고정 폭 정수(int32_t 등)를 사용한다. | No | - | - |
| **C-05-02** | 모든 지역 변수는 선언과 동시에 초기화하거나 사용 전 할당한다. | Yes | clang-tidy | - |
| **C-05-03** | 인터럽트 공유 변수 등은 volatile로 선언한다. | No | - | - |
| **C-05-04** | 재귀 함수(Recursion) 사용을 금지한다. | Yes | clang-tidy | - |
| **C-05-05** | switch 문에는 default 분기를 작성한다. | Yes | clang-tidy | - |
| **C-05-06** | 외부 입력 값은 사용 전 유효 범위 및 무결성을 검증한다. | No | - | - |
| **C-05-07** | strcpy 대신 snprintf 등 길이 검사 포함 함수를 사용한다. | Yes | clang-tidy / checkpatch | - |
| **C-05-08** | 민감 데이터 소거 시 memset 대신 memset_s를 사용한다. | No | - | - |
| **C-05-09** | 보안 데이터 비교 시 timingsafe_memcmp를 사용한다. | No | - | - |
| **C-05-10** | 메모리 영역 중첩 가능 시 memcpy 대신 memmove를 사용한다. | No | - | - |
| **C-05-11** | 동적 할당 메모리는 반드시 해제됨을 보장한다. | No | - | - |

---

## Recommendations

### 1. 즉시 개선 가능 (Low Effort, High Impact)

`lint-c`가 현재 regex 기반으로 11개 규칙만 검사하고 있음. 다음 방법으로 커버리지를 크게 높일 수 있음:

```bash
# Option A: clang-format/clang-tidy 직접 호출 추가
clang-format --style=file:.clang-format --dry-run --Werror "$file"
clang-tidy "$file" -- -std=c17

# Option B: pre-commit 훅 활성화
pre-commit install
pre-commit run --all-files
```

### 2. 커버리지 목표

| Phase | Target | Rules | Coverage |
|:------|:-------|------:|:---------|
| Current | `lint-c` regex only | 12 | 16% |
| Phase 1 | + clang-format | 34 | 45% |
| Phase 2 | + clang-tidy | 44 | 58% |
| Phase 3 | + AI review | 63 | 83% |

### 3. 미구현 규칙 (도구로 검사 불가)

다음 13개 규칙은 자동화 검사가 어려우며 수동 코드 리뷰 필요:
- C-01-28, C-02-13, C-02-15, C-02-17, C-03-07, C-03-08
- C-04-11, C-05-01, C-05-03, C-05-06, C-05-08, C-05-09, C-05-10, C-05-11

---

## Legend

- **soc-vnv (Tool)**: 외부 프로젝트에서 제안하는 검사 도구
- **agent-context (Actual)**: 현재 `agent-context`에서 실제 구현된 검사
- `lint-c` (regex): `tools/lint/scripts/rules/c_rules.sh` 기반 정규식 검사
- AI review (optional): `tools/lint/scripts/test_c_ai_review.sh` (Ollama 필요)

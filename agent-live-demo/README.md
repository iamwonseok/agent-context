# AI Agent Evolution Demo

AI Agent의 진화 과정을 5단계로 시각화하는 데모입니다.

## 진화 단계

```
raw-intelligence -> role-and-persona -> skills-inheriting-role -> agentize -> squad
```

| Step | 이름 | 의미 | 핵심 차이 |
|------|------|------|----------|
| 01 | raw-intelligence | 기본 지능 | 학습된 지식으로 설명만 출력 |
| 02 | role-and-persona | 역할과 페르소나 | 전문가 스타일로 코드 출력 (행동 불가) |
| 03 | skills-inheriting-role | 역할 + 스킬 | **실제 파일 생성/컴파일/실행** |
| 04 | agentize | 에이전트화 | 에러 발생 시 **자동 분석/수정/재시도** |
| 05 | squad | 팀 협업 | 전문가 에이전트들이 **분업** |

## 시나리오: 동일한 입력, 진화하는 출력

모든 단계에서 **동일한 주제(swap 프로그램)**를 요청합니다.
각 단계별로 AI가 어떻게 다르게 대응하는지 비교할 수 있습니다.

### 입력과 출력 비교

| Step | 입력 | AI 대응 |
|------|------|---------|
| 01 | "swap 프로그램 만들어줘" | 코드 + 사용법 설명 출력 |
| 02 | 동일 | 전문가 스타일 코드만 출력 (간결, null 체크) |
| 03 | 동일 | 파일 생성 -> 컴파일 -> 실행 -> 결과 출력 |
| 04 | 동일 | 컴파일 에러 -> 분석 -> 수정 -> 재시도 -> 성공 |
| 05 | "swap 라이브러리 프로젝트" | Manager -> Architect -> Engineer -> Tester 분업 |

### 시스템 헤더 진화

```
01: (없음)
02: [System] Persona: Senior Embedded C Developer
03: [System] Persona: Senior Embedded C Developer | Skills: write_file, compile, run
04: [System] Persona: Senior Embedded C Developer | Skills: write_file, compile, run, read_file, fix_code
05: [System] Squad: Manager, Architect, Engineer, Tester
```

## 요구사항

- Python 3.8+
- VHS (https://github.com/charmbracelet/vhs)
- gcc (Step 03-05 C 컴파일용)

```bash
# macOS
brew install vhs gcc
brew install --cask font-jetbrains-mono
```

## 실행 방법

### 개별 데모 실행 (인터랙티브)

```bash
cd agent-live-demo/01-raw-intelligence
python3 demo.py
```

### GIF 녹화

```bash
cd agent-live-demo/01-raw-intelligence
vhs demo.tape
```

### 전체 데모 녹화

```bash
cd agent-live-demo
./record_all.sh
```

## 디렉터리 구조

```
agent-live-demo/
├── README.md
├── record_all.sh
├── 01-raw-intelligence/
│   ├── demo.py          # 기본 LLM - 설명만 출력
│   └── demo.tape
├── 02-role-and-persona/
│   ├── demo.py          # Persona 적용 - 전문가 스타일
│   ├── agent.md         # Persona 설정 파일
│   └── demo.tape
├── 03-skills-inheriting-role/
│   ├── demo.py          # Persona + Skills - 실제 실행
│   └── demo.tape
├── 04-agentize/
│   ├── demo.py          # ReAct 패턴 - 자율적 에러 수정
│   └── demo.tape
└── 05-squad/
    ├── demo.py          # Multi-Agent - 전문가 분업
    └── demo.tape
```

## 핵심 메시지

```
01 -> 02: "어떻게 말하는가" (스타일 변화)
02 -> 03: "무엇을 할 수 있는가" (행동 가능)
03 -> 04: "문제를 어떻게 해결하는가" (자율성)
04 -> 05: "복잡한 일을 어떻게 하는가" (협업)
```

---
name: av-util-dev-guide
description: "초급 개발자용 실행 가이드 생성 - 구현된 코드를 분석하여 Mermaid 아키텍처 도식화 + 단계별 실행/테스트 가이드를 자동 생성"
argument-hint: "[generate|update|diagram] [feature] [step]"
user-invocable: true
agents:
  default: null
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
autovibe: true
version: "1.0"
created: "2026-02-24"
group: base
tier: null
inherits: null
---

# Dev Guide Gen - 초급 개발자용 실행 가이드 생성기

> **목적**: 구현된 코드를 분석하여 **초급 개발자가 이해하고 직접 실행/테스트할 수 있는 가이드**를 자동 생성합니다.
>
> Mermaid 다이어그램, 모듈 설명, 단계별 실행 방법, 트러블슈팅을 포함합니다.

---

## PDCA Do 자동 트리거

**이 스킬은 `/pdca do` 실행 후 구현이 완료되면 자동으로 호출됩니다.**

### 트리거 조건
- `/pdca do {feature} {step}` 실행 후 구현 코드가 존재할 때
- `output/{step}/CHECKPOINT.md`에 `PASS`가 기록되었을 때
- 사용자가 `/dev-guide-gen generate {feature} {step}` 를 직접 호출할 때
- 사용자가 `/dev-guide-gen {요청내용}` 를 직접 호출할 때

### 자동 실행 흐름 (단계별)
```
/pdca do {feature} {step}      예: /pdca do intent-table-data-population day2
    |
    v
[구현 완료 + CHECKPOINT PASS]
    |
    v
훅 감지: post-bash-devguide-trigger.sh
    |
    v (step 파라미터 전달)
/dev-guide-gen generate {feature} {step}
    |
    v
docs/02-do/{feature}/DEV_GUIDE_{STEP}.md 생성
    예: DEV_GUIDE_DAY2.md
```

### step 파라미터 규칙

| step 값 | 출력 파일명 | 예시 |
|----------|-------------|------|
| `day1` | `DEV_GUIDE_DAY1.md` | Day 1 환경 구축 가이드 |
| `day2` | `DEV_GUIDE_DAY2.md` | Day 2 카테고리/인텐트 가이드 |
| `day{N}` | `DEV_GUIDE_DAY{N}.md` | Day N 실행 가이드 |
| `task1` | `DEV_GUIDE_TASK1.md` | Task 1 구현 가이드 |
| (생략) | `DEV_GUIDE.md` | 전체 통합 가이드 |

**step이 지정되면 해당 단계의 코드만 분석하여 단계별 독립 문서를 생성합니다.**
**step이 없으면 전체 프로젝트를 분석하여 통합 DEV_GUIDE.md를 생성합니다.**

---

## 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `generate {feature} {step}` | 단계별 가이드 생성 | `/dev-guide-gen generate intent-table-data-population day2` |
| `generate {feature}` | 전체 통합 가이드 생성 | `/dev-guide-gen generate intent-table-data-population` |
| `generate [dir]` | 디렉토리 분석 후 가이드 생성 | `/dev-guide-gen generate project_util/alli_intent_gen` |
| `update {feature} {step}` | 단계별 가이드 업데이트 | `/dev-guide-gen update intent-table-data-population day2` |
| `update {feature}` | 전체 가이드 업데이트 | `/dev-guide-gen update intent-table-data-population` |
| `diagram [dir]` | Mermaid 다이어그램만 생성 | `/dev-guide-gen diagram scripts/common` |

---

## 출력 경로

| 대상 | 출력 파일 | 호출 예시 |
|------|-----------|-----------|
| 단계별 (day) | `docs/02-do/{feature}/DEV_GUIDE_DAY{N}.md` | `/dev-guide-gen generate {feature} day{N}` |
| 단계별 (task) | `docs/02-do/{feature}/DEV_GUIDE_TASK{N}.md` | `/dev-guide-gen generate {feature} task{N}` |
| 전체 통합 | `docs/02-do/{feature}/DEV_GUIDE.md` | `/dev-guide-gen generate {feature}` |
| 직접 지정 | `docs/02-do/{custom-path}/DEV_GUIDE.md` | `/dev-guide-gen generate {dir}` |

### 경로 결정 로직

```
인자 파싱:
  args[1] = feature명 (또는 디렉토리)
  args[2] = step명 (day1, day2, task1 등 / 생략 가능)

step이 있는 경우:
  step을 대문자로 변환 → suffix 생성
  day2 → DAY2, task1 → TASK1
  출력: docs/02-do/{feature}/DEV_GUIDE_{SUFFIX}.md

step이 없는 경우:
  출력: docs/02-do/{feature}/DEV_GUIDE.md
```

### 단계별 가이드의 분석 범위

step이 지정되면 **해당 단계의 코드와 산출물만** 분석합니다:

| step | 분석 대상 | 참조 |
|------|-----------|------|
| `day1` | `scripts/day1_*.py` + `output/day1/` | 이전 Day 없음 |
| `day2` | `scripts/day2_*.py` + `output/day2/` | `output/day1/` (입력 데이터) |
| `day{N}` | `scripts/day{N}_*.py` + `output/day{N}/` | `output/day{N-1}/` (입력 데이터) |

**규칙**: 모든 가이드 문서는 `docs/02-do/` 하위에 생성합니다. PDCA Do phase의 산출물로 관리됩니다.

---

## 생성 워크플로우

### 1. 코드 분석 (자동)
- 디렉토리 구조 스캔 (Glob)
- Python/TypeScript 모듈 의존성 파악 (import 추적)
- 설정 파일 분석 (.env, config, requirements.txt)
- 엔트리포인트 식별 (main, __main__, CLI scripts)

### 2. 문서 구조 생성

#### 전체 통합 가이드 (`DEV_GUIDE.md`) — step 생략 시

```markdown
# {프로젝트명} 개발자 가이드

## 1. 프로젝트 개요
   - 목적, 배경, 핵심 개념 (비유 활용)

## 2. 아키텍처
   - 전체 시스템 다이어그램 (Mermaid flowchart)
   - 모듈 관계도 (Mermaid graph)
   - 데이터 흐름도 (Mermaid sequence/flowchart)

## 3. 디렉토리 구조
   - 폴더별 역할 설명
   - 핵심 파일 표시

## 4. 모듈 상세
   - 각 모듈 역할 + 핵심 함수 + 사용 예시
   - 클래스 다이어그램 (Mermaid classDiagram)

## 5. 실행 가이드
   - 사전 준비 (체크리스트)
   - 단계별 실행 방법 (복사-붙여넣기 가능)
   - 예상 출력 (실제 예시)

## 6. 테스트/검증 방법
   - 수동 테스트 절차
   - 자동 검증 방법
   - 예상 결과 vs 실제 결과

## 7. 트러블슈팅
   - 자주 발생하는 오류 + 해결책
   - 환경별 이슈 (WSL2, Mac, Linux)
```

#### 단계별 가이드 (`DEV_GUIDE_DAY{N}.md`) — step 지정 시

```markdown
# {프로젝트명} - Day {N} 개발자 가이드

> 이전 단계: DEV_GUIDE_DAY{N-1}.md (있는 경우 링크)
> 다음 단계: DEV_GUIDE_DAY{N+1}.md (예정인 경우)

## 1. Day {N} 개요
   - 이 단계가 하는 일 (비유 활용)
   - 입력 데이터 (이전 Day 산출물)
   - 출력 산출물 (이번 Day 결과)

## 2. 핵심 스크립트
   - 진입점 파일 설명 (day{N}_*.py)
   - 주요 함수/클래스 설명
   - 데이터 흐름도 (Mermaid sequenceDiagram)

## 3. 실행 방법
   - 사전 확인 (이전 Day CHECKPOINT PASS 여부)
   - 실행 명령어 (복사-붙여넣기)
   - 예상 출력 (실제 실행 결과)

## 4. 산출물 확인
   - 파일 목록 + 건수 + 용량
   - 샘플 데이터 확인 명령어
   - CHECKPOINT.md 확인

## 5. 품질 게이트
   - 검증 항목 목록
   - PASS 기준
   - 실제 결과

## 6. 트러블슈팅
   - 이 단계에서 자주 발생하는 오류
   - 해결 방법

## 7. 다음 단계 미리보기
   - Day {N+1}에서 할 일
   - 필요한 사전 조건
```

### 3. 작성 원칙

- **비유 우선**: 기술 용어 -> 일상 비유 (예: "Connection Pool = 식당 대기열")
- **복사-실행**: 모든 명령어는 바로 복사하여 실행 가능
- **Mermaid 도식화**: 모든 다이어그램은 Mermaid로 작성 → **`/mermaid` 스킬 표준 준수** (색상, 오류 방지, 템플릿)
- **점진적 난이도**: 쉬운 개념 -> 어려운 개념 순서
- **체크박스**: 실행 전후 확인 사항은 체크리스트 형태

---

## 대상 언어/프레임워크

| 언어 | 분석 대상 | 실행 가이드 |
|------|-----------|-------------|
| Python | import, class, def | venv, pip, python3 |
| TypeScript | import, interface, class | {{PKG_MANAGER}}, tsx, node |
| Shell | 스크립트 분석 | bash, chmod |

---

## 품질 기준

- [ ] 모든 명령어가 복사-실행 가능한가?
- [ ] 초급 개발자가 15분 내에 환경 구축 가능한가?
- [ ] 예상 출력이 실제와 일치하는가?
- [ ] 트러블슈팅이 3개 이상 포함되었는가?
- [ ] Mermaid 다이어그램이 전체 흐름을 설명하는가?
- [ ] `/mermaid` 스킬 표준 준수 (다크모드 테마, 오류 방지 10규칙, 통일 색상)?

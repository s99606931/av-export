---
name: av-base-post-qa
description: |
  대량 작업 후 자동 QA 검수 오케스트레이션 스킬.
  종료 프로토콜 STEP 7에서 대량 작업 판정 시 자동 호출되거나 수동으로 실행.
  av-base-qa-reviewer 에이전트에 위임하여 품질 검수 + Closed-Loop 재확인 수행.
autovibe: true
version: "1.0"
created: "2026-02-22"
group: base
argument-hint: "review|advice|re-check|status|history [options]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Write, Edit, Task]
delegates-to: [av-base-qa-reviewer]
---

# av-base-post-qa — AutoVibe Post-QA Skill

## 시작 프로토콜

```
STEP 1: Read .claude/skills/av-base-post-qa/MEMORY.md → 설정 + 이력 로드
STEP 2: 서브커맨드 파싱 + 실행
```

## 서브커맨드

### 1. review (주요 진입점)

**용도**: QA 검수 실행. 종료 프로토콜 STEP 7에서 자동 호출되거나 수동 실행.

**사용법**:
```
/av-base-post-qa review [--scope=<파일목록|폴더패턴>] [--requester=<이름>] [--batch-info=<JSON>]
```

**실행 흐름**:
```
STEP 1: 옵션 파싱
        --scope: 검수 대상 파일/폴더 (미제공 시 git diff HEAD~1 --name-only 기준)
        --requester: 호출 스킬/에이전트 이름
        --batch-info: JSON {"total_items": N, "task_type": "code|design|config|mixed"}

STEP 2: 세션 파일 생성
        경로: .claude/skills/av-base-post-qa/work/{YYYY-MM-DD}-{NNN}.md
        내용: 호출 컨텍스트 기록

STEP 3: av-base-qa-reviewer 에이전트 호출
        컨텍스트 전달: scope, requester, batch_info, work_session, round=1

STEP 4: 결과 수신 + 사용자에게 출력

STEP 5: NEEDS_IMPROVEMENT 또는 FAIL 시
        → 수정 요청 안내 + re-check 사용 안내
```

### 2. advice

**용도**: 특정 세션의 개선사항 재출력 또는 상세화.

**사용법**:
```
/av-base-post-qa advice [--session=<YYYY-MM-DD-NNN>] [--level=MUST|SHOULD|COULD|LEARN]
```

**실행 흐름**:
```
STEP 1: 세션 파일 로드 (미제공 시 최신 세션)
STEP 2: 지정 레벨 개선사항 필터링 후 재출력
STEP 3: 필요 시 av-base-qa-reviewer에게 상세화 요청
```

### 3. re-check

**용도**: 개선사항 반영 후 재검수 (Closed-Loop).

**사용법**:
```
/av-base-post-qa re-check [--session=<YYYY-MM-DD-NNN>]
```

**실행 흐름**:
```
STEP 1: 세션 파일 로드 → 이전 MUST/SHOULD 항목 목록 확인
STEP 2: round 번호 증가 (최대 3)
        3 초과 시 → AskUserQuestion으로 사용자 에스컬레이션

STEP 3: av-base-qa-reviewer 호출
        컨텍스트: 이전 MUST/SHOULD 항목 + round 번호

STEP 4: 결과 수신 + 세션 파일에 라운드별 결과 추가

STEP 5: PASS/PASS_WITH_ADVICE → 세션 종료
        NEEDS_IMPROVEMENT/FAIL → 다시 수정 요청 안내
```

### 4. status

**용도**: 현재 진행 중인 QA 세션 상태 확인.

**사용법**:
```
/av-base-post-qa status
```

**출력**:
```
## 현재 QA 세션 상태

| 항목 | 값 |
|------|-----|
| 세션 파일 | {경로} |
| 현재 라운드 | {N} / 3 |
| 최종 판정 | {판정} |
| MUST 잔여 | {N}건 |
| SHOULD 잔여 | {N}건 |
```

### 5. history

**용도**: 최근 N건 QA 이력 조회.

**사용법**:
```
/av-base-post-qa history [--limit=<N, 기본 5>]
```

**실행 흐름**:
```
STEP 1: .claude/skills/av-base-post-qa/work/ 디렉토리 Glob
STEP 2: 최신 N개 세션 파일 목록 출력
STEP 3: 각 세션의 최종 판정 + 요청자 + 주요 발견 요약
```

## 자동 호출 조건 (종료 프로토콜 STEP 7)

```
av-base-auditor PASS 후:
  조건 (하나 이상 해당 시 자동 호출):
    (a) changed_files >= 10개
    (b) batch_info.total_items >= 5개
    (c) task_type ∈ {batch, migration, generation, bulk, wave, run-all}

  예외 (QA 생략):
    - MEMORY.md만 변경
    - av-base-post-qa 또는 av-base-qa-reviewer 자체 변경
```

## 세션 파일 형식

경로: `.claude/skills/av-base-post-qa/work/{YYYY-MM-DD}-{NNN}.md`

```markdown
# QA 세션 {YYYY-MM-DD}-{NNN}

## 메타데이터
- **requester**: {이름}
- **scope**: {파일 목록 또는 패턴}
- **batch_info**: {total_items, task_type}
- **시작 시각**: {datetime}

## Round 1 결과
{av-base-qa-reviewer 검수 결과 복사}

## Round 2 결과 (필요 시)
{재검수 결과}

## 최종 판정
- **판정**: PASS | PASS_WITH_ADVICE | NEEDS_IMPROVEMENT | FAIL
- **완료 시각**: {datetime}
```

## 종료 프로토콜

```
STEP 1: MEMORY.md 업데이트 (실행 횟수 + 최신 이력)
STEP 2: 세션 파일 완성도 확인 (최종 판정 기록)
```

## 실행 프로토콜 참조

- 종료 프로토콜 STEP 7: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- QA 에이전트: `.claude/agents/av-base-qa-reviewer.md`

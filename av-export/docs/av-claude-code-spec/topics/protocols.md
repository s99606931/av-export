# Protocols — 시작/종료 프로토콜 + 보고서 형식 + 버전 관리

> Plan §7.1~7.3, §13, §17.2 참조.

## 1. 시작 프로토콜 (모든 스킬/에이전트 공통)

```
STEP 1: 자신의 MEMORY.md 존재 확인
        없으면 → SKILL-MEMORY.md.tmpl 또는 AGENT-MEMORY.md.tmpl로 생성
STEP 2: Read 자신의 MEMORY.md (Lazy: 인덱스 먼저, 토픽은 필요 시)
STEP 3: Read 글로벌 MEMORY.md 상단 50줄 (프로젝트 컨텍스트)
STEP 4: 멀티에이전트이면 → work 세션 파일 생성 또는 로드
        경로: .claude/skills/{skill}/work/{YYYY-MM-DD}-{id}.md
STEP 5: 작업 시작
```

## 2. 종료 프로토콜 (모든 스킬/에이전트 공통)

```
STEP 1: 학습 가치 있는 내용 판단
        있으면 → 자신의 MEMORY.md 업데이트 (Lazy: 관련 토픽만)
STEP 2: 전체 영향 핵심 내용 판단
        있으면 → 글로벌 MEMORY.md 업데이트
STEP 3: 멀티에이전트이면 → work 파일에 완료 기록
STEP 4: 신규 컴포넌트 필요성 판단
        있으면 → 감사 에이전트에 new_component_request 전달
STEP 5: av-base-auditor 에이전트 호출 (감사 요청)
        changed_files 목록 + task 요약 + work_session 경로 전달
STEP 6: auditor PASS → STEP 7 진행
        auditor FAIL → 피드백 반영 → 재작업 (최대 3회)

STEP 7: [대량 작업 판정]
        조건 (하나 이상 해당 시 → av-base-post-qa review 자동 호출):
          (a) changed_files >= 10개
          (b) batch_info.total_items >= 5개
          (c) task_type 키워드: batch/migration/generation/bulk/wave/run-all

        예외 (QA 생략 — 일반 작업으로 처리):
          - MEMORY.md만 변경 (L1 Self-Check 충분)
          - av-base-post-qa 또는 av-base-qa-reviewer 자체 변경 (자기 감사 면제)

        대량 작업 → /av-base-post-qa review --scope={changed_files} --requester={requester}
        일반 작업 → 업무 종료
```

## 3. 감사 요청 형식 (Plan §7.3)

감사 에이전트(av-base-auditor)를 호출할 때 다음 정보를 전달:

```
감사 요청:
  requester: {스킬/에이전트 이름}
  task: {수행한 작업 1~2줄 요약}
  changed_files:
    - 파일경로1
    - 파일경로2
  work_session: {work 파일 경로 | null}
  new_component_request:
    needed: true | false
    type: skill | agent | hook | rule  (needed=true일 때)
    name: {제안 이름}
    reason: {필요 이유 1줄}
    priority: high | medium | low
  batch_info:                    # 선택 (대량 작업 판정용 — STEP 7)
    total_items: {처리 항목 수}
    success_count: {성공 수}
    fail_count: {실패 수}
    task_type: code | design | config | mixed
```

## 4. 구조화 보고서 형식 (Plan §17.2)

모든 스킬/에이전트 작업 완료 시 다음 5섹션 보고서를 work 파일 또는 채팅에 작성:

```markdown
## 작업 완료 보고서

### 발견 사항 (Findings)
- [F1] {발견 내용 — 구체적 파일/위치 포함}
- 발견 사항 없으면 "없음" 명시

### 수정 내용 (Changes)
| # | 파일 | 변경 유형 | 설명 |
|---|------|---------|------|
| 1 | {경로} | 생성|수정|삭제 | {변경 내용} |

### 판단 근거 (Rationale)
- {변경 이유 — 스펙/규칙 번호 인용}

### 미해결 사항 (Remaining)
- [ ] {남은 작업} | 없으면 "없음"

### 신규 컴포넌트 제안 (Optional)
- 없음 | {type: skill|agent, name: av-{name}, reason: ...}
```

**강제 규칙**: "완료했습니다"만으로 종료 금지. 발견 사항이 없어도 "없음" 명시.

## 5. 버전 관리 (Plan §13)

### 버전 변경 규칙

```
Minor (x.N 증가): body 내용 수정, scope 변경, 도구 추가/제거
Major (N.0 증가): 상속 구조 변경, 이름 변경, 인터페이스 변경

변경 시 동시 갱신:
  1. frontmatter version 필드 갱신
  2. frontmatter updated 필드 갱신
  3. components.json의 해당 항목 version 갱신
  4. 자식 컴포넌트에 부모 변경 알림 (upgrade 필요 표시)
```

### 버전 이력은 MEMORY.md에 기록

각 컴포넌트 MEMORY.md의 "변경 이력" 섹션에 날짜/버전/변경 내용을 기록한다.

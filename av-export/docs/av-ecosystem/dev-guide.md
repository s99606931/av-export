---
title: AutoVibe 개발자 가이드
description: 새 Skill/Agent/Hook 만드는 법, 그룹 체계, ROUTING_TABLE 확장, 검증 체크리스트
created: "2026-02-24"
---

# AutoVibe 개발자 가이드

> 전체 인덱스: `README.md` | 아키텍처 이해: `architecture.md`

---

## 1. 새 Skill 만드는 법

### 명령어

```bash
/av-vibe-forge skill {name} [--group {group}] [--inherits {parent}]

# 예시
/av-vibe-forge skill acc-code-gen --group {your-group} --inherits saas-code-gen
/av-vibe-forge skill pay-report-gen --group pay
```

### 생성되는 파일

```
.claude/skills/av-{name}/
├── SKILL.md     ← 스킬 정의 자동 생성
└── MEMORY.md    ← 빈 메모리 파일 자동 생성
```

`components.json`에도 자동 등록된다.

### SKILL.md 최소 구조

```markdown
---
name: av-{name}
description: |
  한 줄 역할 설명.
  트리거: {언제 사용하는지}
autovibe: true
version: "1.0"
created: "YYYY-MM-DD"
group: {group}
tier: null
inherits: null
argument-hint: "<subcommand> [args]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Task, Skill, AskUserQuestion]
---

# av-{name} — {제목}

> 한 줄 설명

## 서브커맨드

| # | 커맨드 | 설명 |
|---|--------|------|
| 1 | `run {args}` | 주 실행 |
| 2 | `status` | 현황 조회 |

## 서브커맨드 상세

### 1. run {args}

1. Read 자신의 MEMORY.md
2. {작업 로직}
3. 결과 보고

## 시작/종료 프로토콜

시작: Read MEMORY.md → 컨텍스트 로드
종료: MEMORY.md 업데이트 → av-base-auditor 감사 요청
```

### 스킬 vs 에이전트 선택 기준

```
스킬 선택:
  - 사용자가 직접 /명령어로 호출
  - 여러 단계(서브커맨드)로 구성된 업무
  - 다른 스킬/에이전트에 위임하는 오케스트레이터

에이전트 선택:
  - 자동으로 트리거되어야 함 (scope 기반)
  - 전문 분야에 집중된 단일 역할
  - 다른 스킬의 Task() 호출로 실행
```

---

## 2. 새 Agent 만드는 법

### 명령어

```bash
/av-vibe-forge agent {name} [--group {group}] [--inherits {parent}] [--scope "glob"]

# 예시 — 새 에이전트 (상속 없음)
/av-vibe-forge agent pay-guard --group pay --scope "{{PROJECT_SRC}}/services/core/pay/**"

# 예시 — av-base-auditor 상속
/av-vibe-forge agent pay-auditor --group pay --inherits av-base-auditor \
  --scope "{{PROJECT_SRC}}/services/core/pay/**"
```

### 생성되는 파일

```
.claude/agents/av-{name}.md
.claude/agent-memory/av-{name}/MEMORY.md
```

### 상속 에이전트 필수 섹션

부모 에이전트를 상속하는 경우, body에 4개 섹션이 자동 생성된다.

```markdown
## 상속 컨텍스트
> 이 에이전트는 `av-{parent}`를 상속합니다.
> 작업 시작 전 `.claude/agents/av-{parent}.md`를 Read하여 공통 로직을 확인하세요.

## 오버라이드 항목
| 항목 | 부모 값 | 이 에이전트 값 |
|------|--------|--------------|
| scope | "{parent scope}" | "{축소된 scope}" |
| model | sonnet | haiku  ← 경량화 시 |

## 공통 로직 (부모에서 상속)
[av-{parent}의 모든 로직을 그대로 실행한다]

## {group} 전용 추가 로직
[도메인 특화 검증 로직]
```

### scope 설계 원칙

```
1. Liskov 원칙: 자식의 scope는 부모보다 반드시 좁아야 함
   av-base-auditor: ".claude/**, docs/**, CLAUDE.md"
   av-acc-auditor: "{{PROJECT_SRC}}/services/core/acc/**"  ✅

2. 필요한 파일만 포함 (최소 권한 원칙)
   ❌ "project"  (전체 프로젝트 — 너무 넓음)
   ✅ "{{PROJECT_SRC}}/services/core/pay/**"

3. 멀티 패턴: 쉼표로 구분
   "{{PROJECT_SRC}}/**/*.ts, .claude/**"
```

---

## 3. 새 Hook 만드는 법

### 명령어

```bash
/av-vibe-forge hook {hook-type} {name} [--group {group}]

# 예시
/av-vibe-forge hook PostToolUse acc-write-monitor --group {your-group}
/av-vibe-forge hook PreToolUse pay-security-scanner --group pay
```

### 생성되는 파일

```
.claude/hooks/av-{name}.sh     ← 셸 스크립트
```

settings.json hooks 섹션에 자동 등록된다.

### Hook 구현 템플릿

```bash
#!/bin/bash
# name: av-{name}
# autovibe: true
# version: 1.0
# created: YYYY-MM-DD
# hook-type: PostToolUse
# trigger-tools: Write, Edit
# description: {훅 역할 설명}

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# 필터: 해당 파일만 처리
[ -z "$FILE_PATH" ] && echo '{}' && exit 0
[ ! -f "$FILE_PATH" ] && echo '{}' && exit 0

# 로직 구현
MSG=""
# ... 검사 로직 ...

# 출력: 항상 유효한 JSON
if [ -n "$MSG" ]; then
  echo "{\"systemMessage\":\"av-{name}: $MSG\"}"
else
  echo "{}"
fi
exit 0
```

### hook-type별 특성

| hook-type | 실행 시점 | 차단 가능 | stdin 내용 |
|---------|---------|:-------:|----------|
| SessionStart | 세션 시작 시 | ❌ | 세션 정보 |
| PreToolUse | 도구 실행 전 | ✅ | `{"tool_name":..., "tool_input":{...}}` |
| PostToolUse | 도구 실행 후 | ❌ | `{"tool_name":..., "tool_input":{...}, "tool_response":{...}}` |

---

## 4. 그룹 체계 확장

### 현재 그룹 체계

```
이식 가능 (base + vibe):
  [base]   공통 기반 — 모든 서비스 공유
  [vibe]   AutoVibe 메타 도구

{{PROJECT_NAME}} 전용 (이식 제외):
  [erp]      ERP 전용 도메인 컴포넌트
  [core]     핵심 업무 서비스 (acc, bdg, pay, hcm, slip)
  [extended] 확장 업무 서비스 (tax, ast, gds, ctr 등)
  [platform] 플랫폼 계층 (auth, sys, cmm)
  [ai]       AI 서비스 (ai-eng, ai-rag)
  [pkg]      공유 패키지
```

### 새 그룹 추가

새 프로젝트에 AutoVibe를 이식한 후 도메인 그룹을 추가한다.

```bash
/av-vibe-portable-init customize
→ "그룹 체계 정의" 선택
→ 새 그룹 이름 + 서비스 목록 입력
```

또는 `components.json`에 직접 컴포넌트를 등록할 때 새 그룹명 사용:

```json
{
  "group": "my-new-group",
  "tier": null,
  "autovibe": true
}
```

---

## 5. ROUTING_TABLE에 경로 추가

`/av` 게이트웨이가 자연어를 올바른 스킬로 라우팅하려면 ROUTING_TABLE에 경로를 추가해야 한다.

### 현재 ROUTING_TABLE 위치

```
.claude/skills/av/SKILL.md — "Phase 2 — Component Matching (ROUTING_TABLE)" 섹션
```

### 경로 추가 방법

#### 방법 A: av-vibe-portable-init customize (권장)

```bash
/av-vibe-portable-init customize
→ "ROUTING_TABLE 항목 추가" 선택
→ intent 카테고리, 도메인, 위임 대상 입력
```

#### 방법 B: 직접 편집

`av/SKILL.md`의 ROUTING_TABLE 섹션에 추가:

```
{intent} + {domain} + {scope}
  → Skill("{skill-name}", "{subcommand} {args}")
  secondary: {agent-name} (보조 에이전트)
```

예시 — 신규 pay 서비스 경로:

```
creation + backend/api/db + pay
  → Skill("av-do-orchestrator", "run backend pay")
  secondary: av-do-db-agent, av-do-backend-agent

analysis + pay + code
  → Task("av-pay-auditor", "Level 2")
```

---

## 6. 레지스트리 직접 등록 (수동)

`/av-vibe-forge`를 사용하지 않고 직접 만든 경우 `components.json`에 추가 후 검증:

```bash
/av-vibe-forge validate av-{name}
```

핵심 필드: `group, version, inherits, file, memory(에이전트/스킬), model(에이전트), scope(에이전트), autovibe: true`

---

## 7. 검증 체크리스트

새 컴포넌트 생성 완료 후 확인할 사항.

### 필수 확인 항목

```
□ frontmatter 필수 필드 모두 존재
  - Skill: name, description, autovibe, version, created, group,
           argument-hint, user-invocable, allowed-tools
  - Agent: name, description, autovibe, version, created, group,
           tools, model, scope

□ autovibe: true 설정됨

□ av- 접두사 + kebab-case + 최대 4단어
  ✅ av-acc-code-gen   ❌ av-accounting-code-generator

□ group 설정 (base/vibe/erp/core/...)
  - base 그룹이면 그룹 접두사 없음: av-base-auditor (not av-base-auditor)

□ components.json에 등록됨
  → /av-vibe-forge validate {name} 실행

□ MEMORY.md 파일 존재
  - .claude/skills/{name}/MEMORY.md  (스킬)
  - .claude/agent-memory/{name}/MEMORY.md  (에이전트)
```

### 상속 컴포넌트 추가 확인

```
□ inherits 필드에 부모 이름 (av- 포함)

□ scope가 부모보다 좁거나 같음 (Liskov 원칙)

□ body에 4섹션 포함:
  "상속 컨텍스트", "오버라이드 항목",
  "공통 로직 (부모에서 상속)", "{group} 전용 추가 로직"

□ 부모의 children 배열에 자식 이름 등록됨
  components.json → 부모 항목 → "children": ["av-{child}"]
```

### av-vibe-forge 검증 명령어

```bash
# 단일 컴포넌트 검증
/av-vibe-forge validate av-{name}

# 전체 생태계 건강도 확인
/av-vibe-forge health

# 상속 트리 시각화
/av-vibe-forge tree
```

---

## 8. 버전 관리 + 이식

**버전 변경**: Minor (body/scope/도구 수정) → x.N+1 | Major (상속 변경/이름 변경) → N+1.0
변경 시 `frontmatter.version`, `frontmatter.updated`, `components.json.version` 동시 갱신.
상세: `.claude/docs/av-claude-code-spec/topics/protocols.md` §5

**이식 패키지**: base+vibe 그룹 + autovibe=true 컴포넌트만 추출 (~38개)

```bash
/av-vibe-forge export --portable  # av-export/ 생성
/av-vibe-portable-init setup           # 대상 프로젝트에서 실행
```

상세: `.claude/docs/av-portable-guide.md`

---

## 참조

| 문서 | 내용 |
|------|------|
| `architecture.md` | OOP 상속 + 위임 패턴 이해 |
| `component-types.md` | 각 유형 frontmatter 전체 필드 |
| `execution-flow.md` | 시작/종료 프로토콜 |
| `.claude/docs/av-claude-code-spec/topics/naming-rules.md` | 네이밍 6대 규칙 |
| `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md` | frontmatter 상세 |
| `.claude/docs/av-portable-guide.md` | 이식 완전 가이드 |
| `.claude/registry/components.json` | 전체 컴포넌트 데이터 |

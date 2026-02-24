---
name: av
description: |
  AutoVibe 마스터 게이트웨이. 자연어 요청을 분석하여 80개+ 컴포넌트(Agent/Skill/Hook/Rule) 중
  최적 스킬/에이전트를 자동 선정하고 실행을 위임한다. Post-work 최적화도 제공.
  직접 구현하지 않고 모든 실행을 기존 스킬/에이전트에 위임하는 단일 진입점.
autovibe: true
version: "1.0"
created: "2026-02-24"
group: vibe
tier: meta
inherits: null
argument-hint: "[run|find|optimize|health|stats] [요구사항|옵션]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Task, Skill, AskUserQuestion]
delegates-to: dynamic
---

# av — AutoVibe 마스터 게이트웨이

> {{PROJECT_NAME}} AutoVibe 생태계의 단일 진입점. 자연어 요청 → 최적 컴포넌트 자동 선정 → 위임 실행.
> `av-vibe-forge`가 컴포넌트를 **만드는** 도구라면, `av`는 컴포넌트를 **쓰는** 게이트웨이.

## 아키텍처 계층

```
Layer 3 (User Gateway):  /av              ← 자연어 → 컴포넌트 선정 → 실행
Layer 2 (Domain):        av-do-orchestrator, av-erp-migration, av-legacy-blueprint ...
Layer 1 (Meta):          av-vibe-forge    ← 컴포넌트 생성/관리
```

## 서브커맨드 전체 (6종)

| # | 커맨드 | 설명 |
|---|--------|------|
| 1 | `run {자연어}` | 요구사항 분석 → 최적 컴포넌트 선정 → Skill() 위임 실행 |
| 2 | `find {자연어}` | 요구사항에 맞는 컴포넌트 추천만 (실행 없음) |
| 3 | `optimize [token\|component\|config\|all]` | Post-work 최적화 → Task(av-base-optimizer) 위임 |
| 4 | `health` | 생태계 건강도 종합 보고서 (100점 스코어) |
| 5 | `stats [--top N]` | 컴포넌트 사용 빈도/성공률 통계 |
| 6 | (인자 없음) | AskUserQuestion으로 의도 파악 대화형 모드 |

---

## 서브커맨드 상세

### 1. run {자연어 요구사항}

자연어 요청을 분석하여 최적 컴포넌트에 위임 실행하는 핵심 서브커맨드.

#### Phase 1 — Intent Classification (키워드 기반)

요구사항을 8개 카테고리로 분류:

```
[creation]      구현, 생성, 만들기, 개발, implement, create, build
[analysis]      분석, 검토, 확인, 감사, analyze, review, check, audit
[migration]     마이그레이션, 이전, migration, migrate, legacy
[optimization]  최적화, 개선, 리팩토링, optimize, refactor, improve
[documentation] 문서, 설계, 스펙, doc, design, spec, blueprint
[testing]       테스트, E2E, QA, test, e2e, quality
[configuration] 설정, 커밋, 동기화, setup, commit, sync, config
[meta-management] 스킬 생성, 에이전트 생성, forge, create skill/agent
```

도메인 컨텍스트 추출:
```
modules   : acc|bdg|pay|hcm|ctr|ast|gds|tax|cmm|elc|grf|itf|lnk|slip|sys
layers    : db|api|backend|frontend|e2e|all|fullstack
scope     : erp|legacy|alli|meta
```

#### Phase 2 — Component Matching (ROUTING_TABLE)

```
ROUTING_TABLE (intent + domain → 위임 대상):

creation + backend/api/db/fullstack + {module}
  → Skill("av-do-orchestrator", "run {layer} {module}")
  secondary: av-do-db-agent, av-do-backend-agent, av-do-api-spec-agent

creation + frontend + {module}
  → Skill("av-do-orchestrator", "run frontend {module}")
  secondary: av-erp-uiux-guard

migration + any
  → Skill("av-erp-migration", "run {module}")
  secondary: av-erp-migrator, av-erp-migration-qa

documentation + blueprint/legacy
  → Skill("av-legacy-blueprint", "enhance {module}/{sub}/{id}")
  secondary: av-legacy-func-analyzer, av-oracle-schema-mapper, av-uiux-blueprint-generator

documentation + ui-ux/design
  → Skill("av-erp-uiux-dev", "sync {module}")

testing + e2e
  → Skill("av-e2e-ui-tester", "{module}")
  secondary: av-do-e2e-agent

testing + quality/lint/build
  → Skill("av-base-code-quality", "{target}")
  secondary: av-base-quality-auditor

optimization + refactor/extract
  → Skill("av-base-refactor", "analyze {target}")
  secondary: av-base-refactor-advisor

optimization + token/component/config
  → Task("av-base-optimizer", "{mode} {target}")

analysis + code/security/architecture
  → Task("av-base-auditor", "Level 2")
  secondary: av-vibe-vibecoder (gap analysis)

analysis + frontend/uiux
  → Task("av-erp-uiux-guard", "{module}")

analysis + frontend/guard
  → Skill("av-erp-fe-audit", "fix {target}")
  secondary: av-erp-fe-auditor

configuration + commit/git
  → Skill("av-base-git-commit", "commit {message}")
  secondary: av-base-git-committer

configuration + sync/claude-md
  → Skill("av-base-sync", "update")
  secondary: av-base-sync-auditor

meta-management + create + skill
  → Skill("av-vibe-forge", "skill {name}")

meta-management + create + agent
  → Skill("av-vibe-forge", "agent {name}")

meta-management + health/validate
  → Skill("av-vibe-forge", "health")

[fallback] 매칭 실패
  → AskUserQuestion으로 선택지 제시
```

#### Phase 3 — Orchestration (신뢰도 기반)

```
신뢰도 계산:
  카테고리 매칭:  +4점 (명확한 키워드 존재)
  도메인 매칭:    +3점 (모듈명/레이어 명시)
  스코프 매칭:    +2점 (erp/legacy/meta 명시)
  이력 매칭:      +1점 (이전 성공 이력)

  신뢰도 >= 8: 직접 실행 (사용자 확인 없음)
  신뢰도 5~7:  선정된 컴포넌트 + 근거 표시 후 확인
  신뢰도 < 5:  AskUserQuestion → 선택지 2~4개 제시
```

실행 흐름:
```
1. Read .claude/skills/av/MEMORY.md → 이전 이력 로드
2. 인자 파싱 → intent + domain 추출
3. ROUTING_TABLE 매칭 → 위임 대상 + 신뢰도 계산
4. 신뢰도별 분기:
   >= 8: "→ {skill} 실행 중..." 출력 후 Skill() 위임
   5~7: "이 요구사항에는 {skill}이 적합합니다. 실행할까요?" 확인
   < 5: AskUserQuestion → 선택지 제시
5. Skill() 또는 Task() 위임 실행
6. MEMORY.md 라우팅 이력 업데이트 (최근 5건 유지)
```

**사용 예시:**
```
/av run acc 백엔드 구현
  → av-do-orchestrator run backend acc

/av run 레거시 acc/bdg/AR1001 분석 및 설계문서 생성
  → av-legacy-blueprint enhance acc/bdg/AR1001

/av run 프론트엔드 한국어 통일 검사
  → av-erp-uiux-guard 또는 av-ui-i18n-guard

/av run {{BACKEND_FRAMEWORK}} 코드 리팩토링 기회 분석
  → av-base-refactor analyze

/av run 신규 acc 전용 감사 에이전트 생성
  → av-vibe-forge agent acc-new-auditor
```

---

### 2. find {자연어 요구사항}

요구사항에 맞는 컴포넌트를 추천하되 실행하지 않는다.

```
1. run과 동일한 Phase 1~2 수행
2. 실행 없음 — 추천 결과만 출력:

   ─────────────────────────────────
   요구사항: "acc 회계 백엔드 API 구현"
   ─────────────────────────────────
   🎯 Primary: av-do-orchestrator (신뢰도: 9/10)
      명령어: /av-do-orchestrator run backend acc
      이유: creation+backend+acc → av-do-orchestrator 직접 매핑

   🔧 Secondary 에이전트:
      - av-do-db-agent: {{ORM_NAME}} 스키마 구현
      - av-do-backend-agent: {{BACKEND_FRAMEWORK}} Controller/Service
      - av-do-api-spec-agent: OpenAPI 3.1 스펙

   💡 대안 스킬:
      - av-legacy-blueprint: 레거시 기반 설계문서 먼저 필요 시
   ─────────────────────────────────
3. MEMORY.md 이력 미업데이트 (실행 아님)
```

---

### 3. optimize [token|component|config|all]

Post-work 최적화. `av-base-optimizer` 에이전트에 위임.

```
모드별 동작:

token:
  Task("av-base-optimizer") → 분석:
  - CLAUDE.md 토큰 예산 분석
  - .claude/rules/**  중복 콘텐츠 감지
  - 에이전트/스킬 description 토큰 비용 계산
  - MCP memory 중복 엔트리 식별
  출력: "절감 가능 토큰: ~{N}토큰/세션" 보고서

component:
  Task("av-base-optimizer") → 분석:
  - MEMORY.md 이력 스캔 → 사용 빈도 0인 컴포넌트 식별
  - components.json 등록 vs 실제 파일 교차 검증
  - 중복 기능 컴포넌트 쌍 감지
  출력: "미사용 {N}개, 중복 의심 {M}쌍" 목록

config:
  Task("av-base-optimizer") → 분석:
  - CLAUDE.md/rules 파일 크기 분석 (200~400줄 기준)
  - Hook 실행 비용 분석 (느린 훅 식별)
  - .mcp.json 미사용 서버 감지
  출력: "설정 최적화 {N}건 권장" 보고서

all: token → component → config 순차 실행 후 종합 보고서
```

---

### 4. health

생태계 건강도 종합 보고서. av-vibe-forge health를 내부 호출 + 추가 분석.

```
1. Skill("av-vibe-forge", "health") → 기본 건강도 데이터 수집
2. 추가 분석:
   - MEMORY.md 업데이트 빈도 (30일 미갱신 → STALE)
   - 이력 기반 오류율 (MEMORY.md 라우팅 이력에서)
   - components.json version 필드 null 개수
3. 100점 스코어 계산:
   - 기본점수: 100
   - UNREGISTERED: -5점/개
   - MISSING: -10점/개
   - NO_MEMORY: -3점/개
   - STALE: -2점/개
   - DEPTH_VIOLATION: -5점/개
4. 출력:

   ════════════════════════════════
   🏥 AutoVibe 생태계 건강도: 87/100
   ════════════════════════════════
   ✅ OK: 76개
   ⚠️ STALE: 3개 (30일 미갱신)
   ❌ MISSING: 1개
   ────────────────────────────────
   권장 조치:
   - /av-vibe-forge validate av-xxx (MISSING 복구)
   - /av optimize component (미사용 정리)
   ════════════════════════════════
```

---

### 5. stats [--top N]

컴포넌트 사용 빈도/성공률 통계.

```
1. Read .claude/skills/av/MEMORY.md → 라우팅 이력
2. Read .claude/agent-memory/*/MEMORY.md → 에이전트 이력
3. 집계:
   - 컴포넌트별 호출 횟수
   - 성공/실패율 (이력에서 추정)
   - 마지막 사용일

4. 출력 (--top 5 기본):
   ─────────────────────────────
   📊 컴포넌트 사용 통계 (상위 5)
   ─────────────────────────────
   1. av-erp-migration    23회 | 성공률 91%
   2. av-do-orchestrator  18회 | 성공률 89%
   3. av-legacy-blueprint 12회 | 성공률 95%
   4. av-base-code-quality      8회 | 성공률 100%
   5. av-base-git-commit         6회 | 성공률 100%
   ─────────────────────────────
   총 실행: {N}회 | 평균 신뢰도: {X}/10
```

---

### 6. (인자 없음) — 대화형 모드

```
AskUserQuestion:
  "무엇을 하려고 하시나요?"
  옵션:
  1. ERP 구현 (DB/API/Backend/Frontend)
  2. 레거시 분석/마이그레이션
  3. UI/UX 설계 동기화
  4. 코드 품질 검사
  5. AutoVibe 컴포넌트 생성/관리

선택에 따라 추가 질문 또는 run 서브커맨드 실행
```

---

## 실행 프로토콜

### 시작 프로토콜
```
STEP 1: Read .claude/skills/av/MEMORY.md
STEP 2: 인자 파싱 → 서브커맨드 + 요구사항 분리
STEP 3: 서브커맨드 실행
```

### 종료 프로토콜
```
STEP 1: MEMORY.md 라우팅 이력 업데이트 (run 서브커맨드 시)
STEP 2: 총 실행 횟수 + 평균 신뢰도 갱신
STEP 3: 학습 필요 내용 → MEMORY.md 업데이트
        전체 영향 내용 → 글로벌 MEMORY.md 업데이트
STEP 4: av-base-auditor Level 1 Self-Check (조회 전용)
        run/optimize 실행 시 → av-base-auditor Level 2
```

## 신규 프로젝트 이식 모드 (ROUTING_TABLE 초기화)

> `/av-vibe-portable-init setup` 실행 후 av/SKILL.md의 ROUTING_TABLE이 범용 기본값으로 교체된다.
> 이 섹션은 이식 후 상태를 문서화한 것이며, 프로젝트 전용 스킬을 추가하면서 점진적으로 확장한다.

### 이식 직후 ROUTING_TABLE (범용 기본값)

```
creation + any
  → Skill("av-vibe-forge", "skill {name}") 안내
  (전용 구현 스킬 없음 — /av-vibe-forge skill로 먼저 생성)

analysis + code/security/architecture
  → Task("av-base-auditor", "Level 2")

optimization + refactor
  → Skill("av-base-refactor", "analyze {target}")

optimization + token/component/config
  → Task("av-base-optimizer", "{mode} {target}")

configuration + commit/git
  → Skill("av-base-git-commit", "commit {message}")

configuration + sync/claude-md
  → Skill("av-base-sync", "update")

meta-management + create + skill
  → Skill("av-vibe-forge", "skill {name}")

meta-management + create + agent
  → Skill("av-vibe-forge", "agent {name}")

meta-management + health/validate
  → Skill("av-vibe-forge", "health")

testing + quality/lint/build
  → Skill("av-base-code-quality", "{target}")

[fallback] 매칭 실패
  → AskUserQuestion으로 선택지 제시
```

### ROUTING_TABLE 확장 방법

도메인 전용 스킬 생성 후 ROUTING_TABLE에 경로 추가:

```bash
# 1. 도메인 스킬 생성
/av-vibe-forge skill {service}-impl --group {group}

# 2. ROUTING_TABLE 확장
/av-vibe-portable-init customize
→ "ROUTING_TABLE 항목 추가" 선택
```

---

## 참조 파일

| 파일 | 용도 |
|------|------|
| `.claude/registry/components.json` | 전체 컴포넌트 목록 (동적 라우팅용) |
| `.claude/skills/av-vibe-forge/SKILL.md` | 위임 패턴 참조 모델 |
| `.claude/docs/av-portable-guide.md` | AutoVibe 이식 완전 가이드 |
| `.claude/skills/av-do-orchestrator/SKILL.md` | Phase 기반 오케스트레이션 패턴 |
| `.claude/docs/av-claude-code-spec/topics/protocols.md` | 시작/종료 프로토콜 |
| `.claude/docs/av-claude-code-spec/topics/naming-rules.md` | 네이밍 규칙 (예외 조항 포함) |

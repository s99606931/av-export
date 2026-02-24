---
name: av-vibe-portable-init
description: |
  AutoVibe 프레임워크를 다른 프로젝트에 초기화하는 원클릭 이식 스킬.
  export된 portable 패키지를 기반으로 components.json, naming-rules,
  ROUTING_TABLE, hooks를 자동 설정한다.
autovibe: true
version: "1.0"
created: "2026-02-24"
group: vibe
tier: meta
inherits: null
argument-hint: "setup|verify|customize"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# av-vibe-portable-init — AutoVibe 이식 초기화

> AutoVibe 생태계를 새 프로젝트에 원클릭으로 이식하는 스킬.
> `av-vibe-forge export --portable`로 내보낸 패키지를 기반으로 동작.

## 서브커맨드 전체 (3종)

| # | 커맨드 | 설명 |
|---|--------|------|
| 1 | `setup` | 초기 설정 (8단계 자동화) |
| 2 | `verify` | 설치 검증 및 PASS/FAIL 보고 |
| 3 | `customize` | 추가 커스터마이징 |

---

## 서브커맨드 상세

### 1. setup

AutoVibe를 새 프로젝트에 완전 초기화하는 핵심 서브커맨드. 8단계 자동 실행.

```
STEP 1: 사전 검사
  - .claude/ 디렉토리 존재 확인
    없으면 생성 (mkdir -p .claude/{skills,agents,hooks,rules,docs,registry})
  - .claude/registry/components.json 존재 시 → 충돌 경고
    AskUserQuestion: "기존 components.json이 있습니다."
    옵션: "덮어쓰기(기존 삭제)" / "병합(base+vibe만 추가)" / "취소"

STEP 2: 프로젝트 정보 수집 (AskUserQuestion)
  Q1: "프로젝트 이름은?" (텍스트 입력) → {{PROJECT_NAME}}
  Q2: "기술 스택은?"
      옵션: "{{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}}" / "FastAPI+React" / "Django+React" / "Go+React" / "기타"
      → {{BACKEND_FRAMEWORK}} / {{FRONTEND_FRAMEWORK}}
  Q3: "도메인 그룹을 정의해주세요 (예: [core] user, order [extended] report, analytics)"
      (텍스트 입력 — 비워도 기본값 사용)
  Q4: "소스 루트 경로는?" (텍스트 입력, 기본값: src) → {{PROJECT_SRC}}
      예시: "src" (단순), "packages/backend/src" (모노레포)
  Q5: "npm 패키지 스코프?" (텍스트 입력, 비워두면 none) → {{PACKAGE_SCOPE}}
      예시: "@myapp", "@myorg" (없으면 Enter 건너뜀)
  Q6: "멀티테넌트 필드명?" (텍스트 입력, 기본값: none) → {{MULTI_TENANT_FIELD}}
      예시: "{{MULTI_TENANT_FIELD}}", "organizationId" (단일테넌트면 Enter 건너뜀)

★ STEP 2.5: Hydrate (플레이스홀더 → 실제값 일괄 치환)
  Read .claude/skills/av-vibe-forge/sanitize-rules.json → 플레이스홀더 규칙 로드

  치환 맵 구성 (STEP 2 수집값 기반):
    {{PROJECT_NAME}}          → Q1 입력값
    {{PROJECT_ROOT}}          → pwd (현재 디렉토리 자동 감지)
    {{PROJECT_SRC}}           → Q4 입력값 (기본: "src")
    {{PACKAGE_SCOPE}}         → Q5 입력값 (없으면 "@{project_name_lowercase}")
    {{BACKEND_FRAMEWORK}}     → Q2 스택 파싱 ({{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}} → {{BACKEND_FRAMEWORK}})
    {{FRONTEND_FRAMEWORK}}    → Q2 스택 파싱 ({{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}} → {{FRONTEND_FRAMEWORK}})
    {{ORM_NAME}}              → Q2 기반 자동 설정 ({{BACKEND_FRAMEWORK}} → {{ORM_NAME}}, FastAPI → SQLAlchemy, 기타 → "none")
    {{MESSAGING_SYSTEM}}      → "none" (기본값, 이후 customize로 변경 가능)
    {{MONOREPO_TOOL}}         → "none" (기본값)
    {{LINTER_NAME}}           → "ESLint" (기본값, {{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}}이면 "{{LINTER_NAME}}")
    {{PKG_MANAGER}}           → "npm" (기본값, {{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}}이면 "{{PKG_MANAGER}}")
    {{BUILD_COMMAND}}         → "npm run build" (기본값)
    {{MULTI_TENANT_FIELD}}    → Q6 입력값 (기본: "none")
    {{PROJECT_DOMAIN}}        → "(enter your domain description)"

  치환 실행:
    1. .claude/ 내 모든 .md 파일 대상 일괄 치환 (Glob: .claude/**/*.md)
    2. .claude/registry/components.json 플레이스홀더 치환
    3. {{MULTI_TENANT_FIELD}}=none인 경우:
       → {{MULTI_TENANT_FIELD}} 관련 라인 자동 제거 ({{ORM_NAME}} 규칙, 감사 체크 항목 등)
    4. 스택 프리셋 적용 (sanitize-rules.json stack_presets 기반):
       - av-base-auditor.md 체크 3 → Q2 스택에 맞는 규칙으로 교체
       - av-base-code-quality SKILL.md 빌드 명령어 → 스택별 명령어로 교체
    5. hydrate-report.json 생성:
       {
         hydrated_at: ISO8601,
         project_name: "{Q1}",
         stack: "{Q2}",
         substitutions: {total: N, by_placeholder: {...}},
         multi_tenant: "{Q6 결과}",
         preset_applied: "{스택 프리셋명}",
         warnings: []
       }

STEP 3: components.json 초기화
  - av-export/portable-components.json 기반으로 생성
  - _meta 섹션:
    version: "3.0"
    description: "{프로젝트명} AutoVibe registry - base+vibe 코어"
  - base+vibe 컴포넌트만 포함 (erp/core/extended 제거)
  - total 카운트: 실제 base+vibe 수량으로 설정

STEP 4: 그룹 체계 커스터마이징
  - naming-rules.md의 ## 2. 그룹 체계 섹션을 STEP 2 Q3 답변으로 교체
    비어있으면 기본 템플릿 유지:
      [platform] 플랫폼 계층 서비스
      [core]     핵심 업무 서비스
      [extended] 확장 업무 서비스
  - av-base-auditor.md 체크 3을 Q2 선택 스택으로 교체:
    {{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}} → "{{BACKEND_FRAMEWORK}} Module/Controller/Service DI 패턴, {{ORM_NAME}} 7 규칙"
    Django+React   → "Django View/Serializer/Model 패턴, ORM 규칙"
    Rails+Vue      → "Rails MVC 패턴, ActiveRecord 규칙"
    Go+React       → "Go Handler/Service/Repository 패턴"
    기타           → "기본 코딩 컨벤션 준수" (스택별 규칙 직접 편집 필요)

STEP 5: ROUTING_TABLE 초기화
  - av/SKILL.md의 ROUTING_TABLE을 범용 기본값으로 교체:

    creation + any
      → Skill("av-vibe-forge", "skill {name}") 또는 직접 구현
      (전용 구현 스킬 아직 없음 — 먼저 /av-vibe-forge skill로 생성 권장)

    analysis + code/security/architecture
      → Task("av-base-auditor", "Level 2")

    optimization + refactor
      → Skill("av-base-refactor", "analyze {target}")
      secondary: av-base-refactor-advisor

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

STEP 6: Hook 등록
  - .claude/settings.json 생성 또는 수정
  - 5개 hook 전체 등록:
    PostToolUse (Write, Edit) → av-post-write-monitor.sh
    SessionStart              → av-session-discovery.sh
    PreToolUse (Write, Edit)  → av-content-scanner.sh
    PreToolUse (Bash)         → av-bash-guard.sh
    PreToolUse (Bash)         → av-pre-commit-docs-sync.sh
  - 경로: "$CLAUDE_PROJECT_DIR"/.claude/hooks/av-{name}.sh

STEP 7: CLAUDE.md 스캐폴딩
  - 프로젝트 루트 CLAUDE.md에 AutoVibe 섹션 추가:

    ## Skills
    | Skill | Purpose |
    |-------|---------|
    | `av` | AutoVibe 마스터 게이트웨이 — 자연어 → 최적 컴포넌트 자동 선정 + 실행 |
    | `av-vibe-forge` | AutoVibe 마스터 오케스트레이터 — skill/agent/hook/rule 생성·검증·관리 |
    | `av-base-code-quality` | 코드 품질 게이트 — lint + typecheck + build 순차 실행 |
    | `av-base-git-commit` | git 커밋 자동화 — Conventional Commits 메시지 자동 생성 |
    | `av-base-sync` | CLAUDE.md 자동 최신화 — 스킬/버전/현황 동기화 |
    | `av-base-refactor` | 리팩토링 — 중복 감지·공통 모듈 추출·재사용 강화 |
    | `av-base-post-qa` | 대량 작업 후 QA 검수 오케스트레이션 |
    | `av-vibe-portable-init` | AutoVibe 이식 초기화 — setup/verify/customize |

    ## AutoVibe Ecosystem
    자기 성장 AI 생태계. 상세: `.claude/registry/components.json`
    스펙: `.claude/rules/av-base-spec.md`

    | 컴포넌트 | 유형 | 용도 |
    |---------|------|------|
    | `av-vibe-forge` | Skill | 마스터 오케스트레이터 |
    | `av-base-auditor` | Agent | 감사 에이전트 (포맷/로직/메모리 검증) |
    | `av-base-optimizer` | Agent | 최적화 에이전트 (토큰/컴포넌트/설정) |

    ## Memory System
    | 계층 | 경로 | 범위 |
    |------|------|------|
    | L1 에이전트 | `.claude/agent-memory/{name}/MEMORY.md` | 해당 에이전트 전용 |
    | L2 스킬 | `.claude/skills/{name}/MEMORY.md` | 해당 스킬 전용 |
    | L4 글로벌 | `~/.claude/projects/{project-slug}/memory/MEMORY.md` | 전체 공유 |

  - 기존 CLAUDE.md 있으면 ## AutoVibe Ecosystem 섹션만 추가
  - 없으면 기본 구조로 신규 생성

STEP 8: 검증 + 보고
  - /av-vibe-forge validate 자동 실행 (base+vibe 컴포넌트 전체)
  - 결과 요약 출력:

    ════════════════════════════════════════
    ✅ AutoVibe 초기화 완료!
    ════════════════════════════════════════
    프로젝트: {프로젝트명}
    기술 스택: {스택}
    ────────────────────────────────────────
    등록된 컴포넌트:
      Agent {N}개 | Skill {N}개 | Hook {N}개 | Rule {N}개
    ────────────────────────────────────────
    다음 단계:
    1. /av-vibe-forge health → 생태계 건강도 확인
    2. /av-vibe-forge agent {name} → 첫 도메인 에이전트 생성
    3. /av-vibe-forge hook PreToolUse {name} → 첫 커스텀 훅 생성
    ════════════════════════════════════════
```

---

### 2. verify

설치 완료 후 무결성 검증.

```
STEP 1: components.json 검증
  - Read .claude/registry/components.json
  - _meta 존재, total 수량 일치 확인
  - 모든 등록 컴포넌트 파일 경로 유효성 확인

STEP 2: 파일 존재 확인
  - base+vibe 컴포넌트 전체 파일 존재 여부 (Glob)
  - hooks 파일 존재 여부 (.claude/hooks/av-*.sh)
  - rules 파일 존재 여부 (.claude/rules/av-*.md)

STEP 3: Hook 등록 확인
  - .claude/settings.json 존재 확인
  - 5개 hook 모두 등록 여부

STEP 4: PASS/FAIL 보고서 출력

  ════════════════════════════════════════
  🔍 AutoVibe 설치 검증 결과
  ════════════════════════════════════════
  components.json:  ✅ PASS (Agent N개, Skill N개, Hook N개, Rule N개)
  파일 무결성:      ✅ PASS (N/N 파일 존재)
  Hook 등록:        ✅ PASS (5/5 등록됨)
  Rule 파일:        ✅ PASS (N개 확인)
  ────────────────────────────────────────
  종합 판정: ✅ 설치 완료 (문제 없음)
  ════════════════════════════════════════

  실패 시:
  components.json:  ❌ FAIL → {오류 내용}
  권장 조치: /av-vibe-portable-init setup 재실행
```

---

### 3. customize

초기화 후 추가 커스터마이징.

```
STEP 1: AskUserQuestion → 커스터마이징 항목 선택
  옵션:
  - "그룹 체계 재정의" → naming-rules.md ## 2. 그룹 체계 수정
  - "ROUTING_TABLE 항목 추가/수정" → av/SKILL.md ROUTING_TABLE 편집
  - "감사 규칙 수정" → av-base-auditor.md 체크 항목 편집
  - "기술 스택 변경" → STEP 2로 이동

STEP 2 (그룹 체계 재정의):
  - 현재 그룹 체계 표시
  - AskUserQuestion: "새 그룹 체계를 입력하세요"
  - Edit naming-rules.md → ## 2. 그룹 체계 교체

STEP 2 (ROUTING_TABLE 추가):
  - 현재 ROUTING_TABLE 표시
  - AskUserQuestion: "추가할 intent+domain → 위임 대상을 입력하세요"
  - Edit av/SKILL.md → ROUTING_TABLE 항목 추가

STEP 2 (감사 규칙 수정):
  - av-base-auditor.md 체크 3 현재 내용 표시
  - AskUserQuestion: "변경할 스택별 규칙을 입력하세요"
  - Edit av-base-auditor.md → 체크 3 교체

STEP 3: 변경사항 요약 출력 + /av-vibe-forge validate 자동 실행
```

---

## 사전 요구사항

```
필수:
- Claude Code CLI 설치 (claude --version)
- git 초기화된 프로젝트 (git init 실행 후)
- {{PROJECT_NAME}}에서 export한 av-export/ 패키지

선택:
- jq 설치 (JSON 처리 자동화에 활용)
```

---

## 실행 프로토콜

### 시작 프로토콜

```
STEP 1: Read .claude/skills/av-vibe-portable-init/MEMORY.md
STEP 2: 인자 파싱 → 서브커맨드 분리
STEP 3: 서브커맨드 실행
```

### 종료 프로토콜

```
STEP 1: 실행 결과 요약 출력
STEP 2: MEMORY.md 이력 업데이트
STEP 3: av-base-auditor Level 2 감사 요청 (setup/customize 시)
        Level 1 Self-Check (verify 시)
```

## 참조 파일

| 파일 | 용도 |
|------|------|
| `.claude/docs/av-portable-guide.md` | 이식 전체 가이드 |
| `.claude/registry/components.json` | 컴포넌트 레지스트리 |
| `.claude/docs/av-claude-code-spec/topics/naming-rules.md` | 그룹 체계 정의 |
| `.claude/rules/av-base-spec.md` | AutoVibe 중앙 규칙 |

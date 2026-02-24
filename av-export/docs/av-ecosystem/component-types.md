---
title: AutoVibe 컴포넌트 유형 상세
description: Skill, Agent, Hook, Rule 유형별 frontmatter, 구조, 예시, 자동 트리거
created: "2026-02-24"
---

# AutoVibe 컴포넌트 유형 상세

> 전체 인덱스: `README.md` | 아키텍처 개요: `architecture.md`

---

## 1. Skill

### 개념

사용자가 `/av-vibe-forge skill` 처럼 직접 호출하는 다단계 업무 처리 오케스트레이터.
스킬은 스스로 구현하지 않고 Agent에 위임하거나 도구를 직접 사용한다.

### 디렉토리 구조

```
.claude/skills/
└── av-{name}/
    ├── SKILL.md     ← 스킬 정의 (frontmatter + 서브커맨드 구현)
    └── MEMORY.md    ← 스킬 메모리 (≤20줄)
```

### frontmatter 필수 필드

```yaml
---
name: av-{name}
description: |
  한 줄 역할 설명.
  트리거 조건 (선택)
autovibe: true
version: "1.0"
created: "YYYY-MM-DD"
group: base|vibe|erp|...
tier: null|meta|platform
inherits: null|av-{parent}
argument-hint: "<subcommand> [args] [--options]"
user-invocable: true|false
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, Skill, AskUserQuestion]
---
```

`allowed-tools`: Agent의 `tools`와 달리 Skill에서만 사용하는 필드명.

### 서브커맨드 구조 (모범: av-vibe-forge)

```markdown
## 서브커맨드 전체 (N종)

| # | 커맨드 | 설명 |
|---|--------|------|
| 1 | `run {args}` | 주 실행 흐름 |
| 2 | `status` | 현황 조회 |

## 서브커맨드 상세

### 1. run {args}

실행 단계:
1. Read 관련 파일
2. 처리 로직
3. Skill() 또는 Task() 위임
```

### 실제 예시: av-vibe-forge

```
스킬 이름: av-vibe-forge
서브커맨드: 14개 (skill, agent, hook, rule, list, validate, spec,
             upgrade, health, export, import, version, tree, audit-request)
위임 대상:
  skill → av-vibe-skill-forge
  agent → av-vibe-agent-forge
  hook  → av-vibe-hook-forge
  rule  → av-vibe-rule-forge
```

### user-invocable 의미

| 값 | 설명 | 호출 방법 |
|----|------|---------|
| `true` | 사용자 직접 `/av-vibe-forge` 명령어 입력 | `/스킬명 서브커맨드` |
| `false` | 다른 스킬이 Skill() 도구로만 호출 | Skill("av-vibe-skill-forge", "...") |

---

## 2. Agent

### 개념

`Task()` 도구 또는 자동 트리거로 실행되는 전문 AI 에이전트.
파일 변경 범위(scope)에 따라 Claude Code가 자동으로 활성화한다.

### 파일 위치

```
.claude/agents/av-{name}.md
.claude/agent-memory/av-{name}/MEMORY.md  ← 에이전트 전용 메모리 (≤30줄)
```

### frontmatter 필수 필드

```yaml
---
name: av-{name}
description: |
  역할 설명 (1~3줄).
  트리거: 어떤 상황에서 자동 활성화되는지
autovibe: true
version: "1.0"
created: "YYYY-MM-DD"
group: base|vibe|erp|...
tier: null
inherits: null|av-{parent}
tools: [Read, Glob, Grep, Write, Edit]
model: sonnet|haiku|opus
scope: "glob pattern"
---
```

### model 선택 기준

| 모델 | 사용 시기 | 예시 |
|------|---------|------|
| `sonnet` | 기본. 대부분의 감사/가드/구현 에이전트 | av-base-auditor, av-erp-backend-guard |
| `haiku` | 경량 작업. 빠른 검사, git 커밋 메시지 | av-base-git-committer, av-base-quality-auditor, av-ui-i18n-guard |
| `opus` | 복잡한 오케스트레이션, 자율 실행 | av-do-orchestrator, av-erp-migrator |

### scope 패턴 예시

```yaml
# 특정 서비스 파일만
scope: "{{PROJECT_SRC}}/services/core/acc/**"

# 여러 패턴 (쉼표 구분)
scope: "{{PROJECT_SRC}}/**/*.{module,controller,service}.ts,{{PROJECT_SRC}}/**/*.prisma"

# 전체 프로젝트
scope: "project"

# .claude/ 내부
scope: ".claude/**"
```

### 자동 트리거 메커니즘

Claude Code는 에이전트의 `scope` 글로브 패턴과 현재 변경 파일 경로를 매칭하여
자동으로 에이전트를 활성화할 수 있다. description에 트리거 조건을 명시한다.

```yaml
# av-erp-backend-guard 예시
description: |
  {{BACKEND_FRAMEWORK}}/{{ORM_NAME}} 패턴 검증 에이전트.
  트리거: *.module.ts, *.controller.ts, *.service.ts, *.prisma 파일 변경 후 호출
scope: "{{PROJECT_SRC}}/services/**/*.{module,controller,service}.ts"
```

### 실제 예시: av-base-auditor

```
이름: av-base-auditor
역할: 모든 av- 스킬/에이전트 종료 프로토콜 Step 5에서 자동 감사
감사 수준:
  L1 Self-Check  → MEMORY.md만 변경 시 (~5초)
  L2 Standard    → 코드/스킬/에이전트 body 수정 (~30초)
  L3 Structural  → 신규 컴포넌트/레지스트리 변경 (~60초)
자식 에이전트: av-acc-auditor, av-erp-migration-qa, av-base-qa-reviewer
```

### 상속 body 구조 (자식 에이전트)

```markdown
## 상속 컨텍스트
> 이 에이전트는 `av-base-auditor`를 상속합니다.
> 작업 시작 전 `.claude/agents/av-base-auditor.md`를 Read하여 공통 로직을 확인하세요.

## 오버라이드 항목
| 항목 | 부모 값 | 이 에이전트 값 |
|------|--------|--------------|
| scope | ".claude/**" | "services/core/acc/**" |

## 공통 로직 (부모에서 상속)
[av-auditor의 체크 1~4 모두 실행]

## acc 전용 추가 로직
[회계 도메인 특화 검증: 복식부기 규칙, 예산 정합성 등]
```

---

## 3. Hook

### 개념

Claude Code 이벤트에 반응하는 Bash 셸 스크립트. 사람의 개입 없이 자동 실행.
PreToolUse는 도구 실행을 차단할 수 있다.

### 파일 위치

```
.claude/hooks/av-{name}.sh
```

### 메타데이터 (frontmatter 대신 주석)

```bash
#!/bin/bash
# name: av-{name}
# autovibe: true
# version: 1.0
# created: YYYY-MM-DD
# hook-type: PreToolUse|PostToolUse|SessionStart
# trigger-tools: Write, Edit       ← 어떤 도구에서 실행되는지
# description: 훅 동작 설명
```

### settings.json 등록 구조

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/av-content-scanner.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "SessionStart": [...]
  }
}
```

### stdin/stdout 규칙

```bash
INPUT=$(cat)  # Claude Code가 JSON으로 도구 입력 전달

# 항상 JSON 출력 (빈 stdout 금지 — 파싱 오류 발생)
echo "{}"                                           # 정상 통과
echo '{"systemMessage": "경고 메시지"}'              # 메시지 전달
echo '{"decision": "block", "reason": "차단 이유"}'  # 실행 차단 (PreToolUse만)
exit 0
```

### 실제 예시: av-content-scanner

```bash
#!/bin/bash
# hook-type: PreToolUse
# trigger-tools: Write, Edit

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# TypeScript 파일만 검사
case "$FILE_PATH" in *.ts|*.tsx) ;; *) echo '{}' && exit 0 ;; esac

W=""
# {{BACKEND_FRAMEWORK}} DI: import type for Service → 런타임 크래시
if grep -qP 'import\s+type\s+\{[^}]*Service' "$FILE_PATH"; then
  W="${W}[DI] import type for Service — {{BACKEND_FRAMEWORK}} DI 런타임 크래시. "
fi

[ -n "$W" ] && printf '{"systemMessage":"av-content-scanner: %s"}' "$W" || echo '{}'
exit 0
```

### 5개 현황 (2026-02-24 기준)

| Hook | 유형 | 트리거 | 주요 기능 |
|------|------|--------|---------|
| av-session-discovery | SessionStart | 세션 시작 | 프로젝트 구조 보고 |
| av-content-scanner | PreToolUse | Write/Edit | 보안 위험 패턴 차단 |
| av-bash-guard | PreToolUse | Bash | 위험 명령어 차단 |
| av-pre-commit-docs-sync | PreToolUse | Bash | git commit 전 문서 체크 |
| av-post-write-monitor | PostToolUse | Write/Edit | 가드 에이전트 라우팅 제안 |

---

## 4. Rule

### 개념

Claude Code 세션 컨텍스트에 항상 자동 주입되는 전역 행동 규칙.
CLAUDE.md에서 참조하거나 `.claude/rules/` 경로에 위치하면 자동 활성화.

### 파일 위치

```
.claude/rules/av-{name}.md
```

### frontmatter

```yaml
---
name: av-{name}
autovibe: true
version: "1.0"
created: "YYYY-MM-DD"
group: base|vibe|...
---
```

### topic 분리 패턴

Rule 파일이 100줄을 초과하면 topic 파일로 분리한다.

```
.claude/rules/av-claude-code-spec.md          ← 인덱스 (≤50줄)
.claude/docs/av-claude-code-spec/topics/
├── frontmatter-spec.md
├── naming-rules.md
├── protocols.md
└── audit-rules.md
```

인덱스 파일에서 토픽을 참조하고, 에이전트는 필요한 토픽만 Lazy Read한다.

### 실제 예시: av-claude-code-spec

```
파일: .claude/rules/av-claude-code-spec.md
역할: 모든 av- 컴포넌트 규칙 인덱스 (frontmatter, naming, protocols, audit)
토픽: 4개 분리 파일 (Lazy Read로 토큰 절약)
```

### 4개 현황 (2026-02-24 기준)

| Rule | group | 역할 |
|------|-------|------|
| av-claude-code-spec | base | AutoVibe 전체 규칙 인덱스 |
| av-api-response-patterns | erp | API 응답 래핑 패턴 규칙 |
| av-base-memory-first | base | 에이전트 유형별 메모리 전략 |
| mermaid-standard | base | Mermaid 다이어그램 표준 |

---

## 5. 유형별 비교 요약

| 항목 | Skill | Agent | Hook | Rule |
|------|-------|-------|------|------|
| 파일 형식 | Markdown + YAML | Markdown + YAML | Bash 스크립트 | Markdown + YAML |
| 호출 방식 | Skill() 도구 | Task() 도구 | 이벤트 자동 | 컨텍스트 자동 주입 |
| 사용자 직접 호출 | ✅ (user-invocable) | ❌ | ❌ | ❌ |
| 메모리 파일 | MEMORY.md | MEMORY.md | ❌ | ❌ |
| 실행 차단 가능 | ❌ | ❌ | ✅ (PreToolUse) | ❌ |
| av- 접두사 | ✅ | ✅ | ✅ | ✅ |
| 상속 가능 | ✅ | ✅ | ❌ | ❌ |

---

## 참조

| 문서 | 내용 |
|------|------|
| `architecture.md` | 3-Layer 구조 + OOP 상속 + 위임 패턴 |
| `execution-flow.md` | 시작/종료 프로토콜 |
| `dev-guide.md` | 새 컴포넌트 만드는 법 |
| `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md` | frontmatter 상세 스펙 |

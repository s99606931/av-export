---
name: av-vibe-agent-forge
description: |
  AutoVibe 에이전트 생성기. AGENT.md.tmpl 기반으로 에이전트 파일 +
  에이전트 메모리 자동 생성. av-vibe-forge agent가 위임 호출.
autovibe: true
version: "1.0"
created: "2026-02-21"
group: vibe
tier: meta
inherits: null
argument-hint: "[name] --group {group} --inherits {parent} --tier {tier}"
user-invocable: false
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Task]
---

# av-vibe-agent-forge — Agent Generator

## 역할

`av-vibe-forge agent [name]`에 의해 위임 호출되는 에이전트 생성기.
스킬과 달리 `tools`, `model`, `scope` 필드가 필수이며,
에이전트 파일은 `.claude/agents/` 경로에 단일 파일로 생성된다.

## av-vibe-skill-forge와의 차이점

| 항목 | skill-forge | agent-forge |
|------|------------|-------------|
| 템플릿 | `SKILL-ADVANCED.md.tmpl` | `AGENT.md.tmpl` |
| 출력 경로 | `.claude/skills/av-{name}/SKILL.md` | `.claude/agents/av-{name}.md` |
| 메모리 경로 | `.claude/skills/av-{name}/MEMORY.md` | `.claude/agent-memory/av-{name}/MEMORY.md` |
| 메모리 템플릿 | `SKILL-MEMORY.md.tmpl` | `AGENT-MEMORY.md.tmpl` |
| 추가 필수 필드 | — | `tools`, `model`, `scope` |
| 추가 입력 항목 | — | model 선택, scope 패턴, tools 목록 |

## Arguments

| 인자 | 필수 | 설명 |
|------|:----:|------|
| `name` | ✅ | 에이전트 이름 (av- 자동 삽입) |
| `--group` | ✅ | 그룹 (base/vibe/acc 등) |
| `--model` | ❌ | LLM 모델 (haiku/sonnet/opus, 기본: sonnet) |
| `--scope` | ❌ | 접근 허용 글로브 패턴 |
| `--inherits` | ❌ | 부모 에이전트 이름 |
| `--tier` | ❌ | 계층 분류 |

## 프로세스 (13단계)

av-vibe-skill-forge와 동일한 13단계 구조:

```
STEP 1-4: 메모리 로드 + 템플릿(AGENT.md.tmpl) + 스펙 규칙 참조
STEP 5-6: 레지스트리 검사 + 부모 분석 (--inherits 시)
STEP 7: 상속 body 구성 (4섹션 필수)
STEP 8: AskUserQuestion →
        - 에이전트 이름 확인
        - model 선택 (haiku/sonnet/opus)
        - scope Glob 패턴 (예: "services/core/acc/**")
        - tools 목록 (기본 제공 후 추가/제거)
        - scope Liskov 준수 확인 (부모보다 좁아야 함)
STEP 9:  Write .claude/agents/av-{name}.md
STEP 10: Write .claude/agent-memory/av-{name}/MEMORY.md
         (AGENT-MEMORY.md.tmpl 기반)
STEP 11: Edit components.json → agents.{name} 등록 + 부모 children
STEP 12: Edit CLAUDE.md → Agents 섹션 업데이트 (필요 시)
STEP 13: 검증 + 메모리 + 감사 (Level 3)
```

## model 선택 기준

| 모델 | 용도 |
|------|------|
| `haiku` | 빠른 단순 작업 (포맷 검사, 파일 분류 등) |
| `sonnet` | 일반 코드 생성, 분석, 표준 작업 (기본) |
| `opus` | 복잡한 아키텍처 설계, 멀티스텝 전략 |

## 오류 처리

- 동일 이름 에이전트 존재: AskUserQuestion → 덮어쓰기 확인
- scope 미제공: `".claude/**"` 기본값 적용 + 경고
- 부모 scope > 자식 scope 위반: FAIL + Liskov 원칙 설명

## 실행 프로토콜 참조

- 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- Frontmatter: `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md`
- 네이밍: `.claude/docs/av-claude-code-spec/topics/naming-rules.md`

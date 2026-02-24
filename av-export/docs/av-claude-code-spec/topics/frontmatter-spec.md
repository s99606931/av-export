# Frontmatter Spec — av- 컴포넌트 유형별 필수/선택 필드

> Plan §12, §10.3 참조. 모든 av- 컴포넌트 frontmatter 기준.

## Agent (`.claude/agents/av-*.md`)

```yaml
---
name: av-{name}                    # 필수 — av- 포함
description: {역할 설명}            # 필수 — 1~3줄
autovibe: true                     # 필수 — AutoVibe 생성 마커
version: "1.0"                     # 필수 — Major.Minor 문자열
created: "YYYY-MM-DD"              # 필수
group: {base|vibe|acc|...}         # 필수 — SSOT 서비스 약칭
tier: {null|platform|core|...}     # 선택 — null이면 생략 가능
inherits: {parent-name|null}       # 선택 — null이면 생략 가능
tools: [Read, Glob, Grep, ...]     # 필수 — 사용 도구 배열
model: {sonnet|haiku|opus}         # 필수 — 기본 sonnet
scope: "{glob pattern}"            # 필수 — 접근 가능 파일 범위
---
```

| 필드 | 필수 | 기본값 | 설명 |
|------|:----:|--------|------|
| name | ✅ | - | av- 접두사 포함 |
| description | ✅ | - | 역할 + 트리거 조건 |
| autovibe | ✅ | true | AutoVibe 마커 |
| version | ✅ | "1.0" | Major.Minor |
| created | ✅ | - | 생성일 |
| group | ✅ | base | SSOT 그룹 |
| tools | ✅ | - | 도구 배열 |
| model | ✅ | sonnet | LLM 모델 |
| scope | ✅ | - | 글로브 패턴 |
| tier | - | null | 계층 분류 |
| inherits | - | null | 부모 컴포넌트 이름 |
| overrides | - | [] | 오버라이드 항목 목록 |
| updated | - | - | 마지막 수정일 |

## Skill (`.claude/skills/av-*/SKILL.md`)

```yaml
---
name: av-{name}                    # 필수
description: {역할 설명}            # 필수
autovibe: true                     # 필수
version: "1.0"                     # 필수
created: "YYYY-MM-DD"              # 필수
group: {base|vibe|acc|...}         # 필수
tier: {null|meta|platform|...}     # 선택
inherits: {parent-name|null}       # 선택
argument-hint: "{args}"            # 필수 — 사용법 힌트
user-invocable: true|false         # 필수 — 사용자가 직접 호출 가능 여부
allowed-tools: [Read, Write, ...]  # 필수 — Skill은 allowed-tools 사용
---
```

## Hook (`.claude/hooks/av-*.sh`)

셸 스크립트이므로 frontmatter 대신 주석으로 메타데이터 기록:

```bash
#!/bin/bash
# name: av-{name}
# autovibe: true
# version: 1.0
# created: YYYY-MM-DD
# hook-type: PreToolUse|PostToolUse|SessionStart
# trigger-tools: Write, Edit
# description: 훅 동작 설명
```

## Rule (`.claude/rules/av-*.md`)

```yaml
---
name: av-{name}
autovibe: true
version: "1.0"
created: "YYYY-MM-DD"
group: {base|vibe|...}
---
```

## 커스텀 필드 (상속 시 추가)

상속 컴포넌트는 다음 필드 추가:

```yaml
inherits: av-{parent-name}      # 부모 컴포넌트 이름 (av- 포함)
tier: core                      # 소속 계층
overrides:                      # 오버라이드 항목 목록
  - scope: "services/core/**"
  - checks: acc-specific
```

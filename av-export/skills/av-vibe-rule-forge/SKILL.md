---
name: av-vibe-rule-forge
description: |
  AutoVibe 룰 생성기. av-claude-code-spec.md 기반으로
  Rule 파일(.claude/rules/av-*.md) 표준 생성 + 레지스트리 등록.
  av-vibe-forge rule 서브커맨드가 위임 호출.
autovibe: true
version: "1.0"
created: "2026-02-21"
group: vibe
tier: meta
inherits: null
argument-hint: "[name] --group {group} --description {desc}"
user-invocable: false
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# av-vibe-rule-forge — Rule Generator

## 역할

`av-vibe-forge rule [name]`에 의해 위임 호출되는 룰 생성기.
av-claude-code-spec.md의 Rule frontmatter 명세를 기반으로
표준 av- Rule 파일을 생성하고 레지스트리에 등록한다.

## av-vibe-skill-forge와의 차이점

| 항목 | skill-forge | rule-forge |
|------|------------|-----------|
| 출력 유형 | SKILL.md + MEMORY.md | 단일 Rule .md |
| 출력 경로 | `.claude/skills/av-{name}/` | `.claude/rules/av-{name}.md` |
| topics/ 지원 | ❌ | ✅ (100줄 초과 시) |
| MEMORY.md | 필수 | 없음 (Rule은 정적 문서) |
| 레지스트리 섹션 | `skills` | `rules` |

## Arguments

| 인자 | 필수 | 설명 |
|------|:----:|------|
| `name` | ✅ | 룰 이름 (av- 자동 삽입) |
| `--group` | ✅ | 그룹 (base/vibe/acc 등) |
| `--description` | ❌ | 1줄 설명 |

## 네이밍 해결 로직

```
"prisma-rules" + --group {your-group}  →  av-acc-prisma-rules
"av-acc-prisma-rules"          →  av-acc-prisma-rules  (중복 삽입 방지)
"style-guide" + --group base   →  av-style-guide       (base는 접두사 생략)
```

## 프로세스 (10단계)

```
STEP 1: Read 자신의 MEMORY.md → 컨텍스트 로드
STEP 2: Read 글로벌 MEMORY.md → 프로젝트 컨텍스트
STEP 3: Read .claude/docs/av-claude-code-spec/topics/frontmatter-spec.md
        → Rule frontmatter 필수 필드 확인
STEP 4: Read .claude/registry/components.json
        → 동일 이름 충돌 검사
STEP 5: AskUserQuestion →
        - 최종 룰 이름 확인
        - 그룹 선택 (base/vibe/acc/bdg 등)
        - 룰의 핵심 내용 구조 (어떤 규칙을 정의하는가)
        - topics/ 분리 필요 여부 (내용이 100줄 초과 예상 시)
STEP 6: Rule .md 구성:
        - frontmatter (name, autovibe, version, created, group)
        - H1 제목 + 목적 요약
        - 섹션별 규칙 정의
        - topics/ 링크 (분리 시)
STEP 7: Write .claude/rules/av-{name}.md
STEP 8: (topics/ 분리 시) mkdir + Write .claude/rules/av-{name}/topics/*.md
STEP 9: Edit .claude/registry/components.json
        → rules.{name} 신규 등록
        → _meta.total.rules +1
STEP 10: 검증 + 메모리 + 감사
         → frontmatter 4필드 확인
         → av- 네이밍 준수 확인
         → 자신의 MEMORY.md 이력 업데이트
         → av-base-auditor 감사 요청 (Level 3)
```

## Rule frontmatter 필수 필드

```yaml
---
name: av-{name}         # av- 접두사 필수
autovibe: true          # AutoVibe 마커
version: "1.0"          # Major.Minor
created: "YYYY-MM-DD"   # 생성일
group: {group}          # base/vibe/acc 등
---
```

## 오류 처리

| 조건 | 처리 |
|------|------|
| 동일 이름 존재 | AskUserQuestion → 덮어쓰기 확인 |
| 레지스트리 미초기화 | 중단 + "components.json 없음" |
| 4단어 초과 이름 | 경고 + 단축 제안 |

## 실행 프로토콜 참조

- 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`
- Frontmatter(Rule): `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md`
- 네이밍: `.claude/docs/av-claude-code-spec/topics/naming-rules.md`

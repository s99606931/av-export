---
name: av-vibe-skill-forge
description: |
  AutoVibe 스킬 생성기. av-skill-advanced.md.tmpl + av-claude-code-spec.md 기반으로
  SKILL.md + MEMORY.md 자동 생성. 상속(--inherits) 지원. av-vibe-forge가 위임 호출.
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

# av-vibe-skill-forge — Skill Generator

## 역할

`av-vibe-forge skill [name]`에 의해 위임 호출되는 스킬 생성기.
Phase 0에서 생성된 템플릿과 스펙 규칙을 기반으로 표준 av- 스킬을 자동 생성한다.

## Arguments

| 인자 | 필수 | 설명 |
|------|:----:|------|
| `name` | ✅ | 스킬 이름 (av- 자동 삽입) |
| `--group` | ✅ | 그룹 (base/vibe/acc/bdg 등) |
| `--inherits` | ❌ | 부모 스킬 이름 |
| `--tier` | ❌ | 계층 (meta/platform/core/extended) |

## 네이밍 해결 로직

```
"acc-code-gen" + --group {your-group}  →  av-acc-code-gen
"av-acc-code-gen"             →  av-acc-code-gen  (중복 삽입 방지)
"auditor" + --group base      →  av-base-auditor       (base는 그룹 접두사 생략)
```

## 프로세스 (13단계)

```
STEP 1: Read 자신의 MEMORY.md → 컨텍스트 로드
STEP 2: Read 글로벌 MEMORY.md → 프로젝트 컨텍스트
STEP 3: Read .claude/templates/av-docs/av-skill-advanced.md.tmpl → 템플릿 로드
STEP 4: Read .claude/rules/av-base-spec.md → 스펙 규칙 참조
STEP 5: Read .claude/registry/components.json
        → --inherits 시: 부모 존재 확인, file 경로 획득
        → 동일 이름 충돌 검사
STEP 6: (--inherits 시) Read 부모 SKILL.md
        → 역할/프로세스/scope/allowed-tools 분석
STEP 7: 상속 body 구성:
        - "상속 컨텍스트" 섹션 (부모 경로 + 참조 지시)
        - "오버라이드 항목" 테이블
        - "공통 로직" 섹션 (부모 참조)
        - "{group} 전용 추가 로직" 섹션
STEP 8: AskUserQuestion →
        - 최종 스킬 이름 확인
        - 오버라이드 항목 (scope 축소 등)
        - user-invocable 여부
        - allowed-tools 추가/제외 항목
STEP 9: Write .claude/skills/{resolved-name}/SKILL.md
STEP 10: Write .claude/skills/{resolved-name}/MEMORY.md
         (av-skill-memory.md.tmpl 기반 초기화)
STEP 11: Edit .claude/registry/components.json
         → skills.{name} 신규 등록
         → 부모 children 배열에 추가 (--inherits 시)
         → _meta.total.skills +1
STEP 12: Edit CLAUDE.md
         → Skills 테이블에 새 행 추가
STEP 13: 검증 + 메모리 + 감사
         → frontmatter 5필드 확인
         → av- 네이밍 준수 확인
         → MEMORY.md 이력 업데이트
         → av-base-auditor 감사 요청 (Level 3)
```

## 오류 처리

| 조건 | 처리 |
|------|------|
| 템플릿 미존재 (Phase 0 미완료) | 중단 + "Phase 0 먼저 실행하세요" |
| 부모 미등록 (--inherits) | 중단 + "components.json에 {parent} 없음" |
| 동일 이름 존재 | AskUserQuestion → 덮어쓰기 확인 |
| 레지스트리 미초기화 | 중단 + "components.json 없음" |
| scope 위반 (자식 > 부모) | 경고 + AskUserQuestion |

## 실행 프로토콜 참조

- 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`
- Frontmatter: `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md`
- 네이밍: `.claude/docs/av-claude-code-spec/topics/naming-rules.md`

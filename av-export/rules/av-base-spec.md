---
name: av-base-spec
autovibe: true
version: "1.0"
created: "2026-02-21"
group: base
---

# AutoVibe Claude Code Spec (av-base-spec)

> 모든 av- 컴포넌트 중앙 규칙 인덱스. 상세는 topics/ 참조.
> **관련 토픽만 선택적 Read** (토큰 절약 — Plan §7.4).

## Quick Reference

- `av-` = AutoVibe 생태계 산출물 (Rule/Agent/Skill/Hook에만 적용)
- `autovibe: true` frontmatter 필수
- 네이밍: `av-{domain}-{name}` (kebab-case, 최대 4단어, 도메인 필수)
- 도메인: `vibe` (메타) | `base` (범용 필수) | `util` (범용 선택) | `erp/do/legacy/...` (프로젝트 전용)
- 버전: `Major.Minor` 문자열 (e.g. `"1.0"`, `"2.1"`)
- 모든 생성은 `/av-vibe-forge`를 통해서만 (레지스트리 자동 등록)

## Topic Index

| Topic | 파일 | 내용 |
|-------|------|------|
| Frontmatter | `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md` | 유형별 필수 필드, YAML 예시 |
| Naming | `.claude/docs/av-claude-code-spec/topics/naming-rules.md` | av- 접두사, 도메인, OOP 상속, 이식 판별 |
| Protocols | `.claude/docs/av-claude-code-spec/topics/protocols.md` | 시작/종료 프로토콜, 보고서 형식, 버전 관리 |
| Audit | `.claude/docs/av-claude-code-spec/topics/audit-rules.md` | 계층별 감사, 셀프 체크, 면제 규칙 |

## Active Alerts

- Phase 0 완료 후 av-base-auditor 일괄 검증 필수 (Phase 2 완료 시점)
- av-base-auditor 자기 감사 면제 (Level 1 Self-Check만 수행)
- 템플릿(.tmpl) 파일에는 av- 미적용 (메타도구이므로)

## Stats

- spec: v1.0 | created: 2026-02-21
- registry: `.claude/registry/components.json`
- templates: `.claude/templates/av-docs/*.tmpl` (5종)

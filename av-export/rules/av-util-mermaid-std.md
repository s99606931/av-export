---
autovibe: true
type: rule
version: "1.0"
created: "2026-02-24"
group: base
name: av-util-mermaid-std
description: Mermaid 다이어그램 작성 표준 (상세 가이드는 /mermaid 스킬 활용)
---

# Mermaid Diagram Standard

> **핵심 원칙**: 모든 Mermaid 다이어그램은 `/mermaid` 스킬의 템플릿과 검증 도구를 사용하여 작성한다.

## 1. 작성 워크플로우

1. **템플릿 조회**: `/mermaid template [type]` 명령어로 기본 코드 확보
   - `flowchart`, `sequence`, `er`, `class`, `state`, `gantt` 등
2. **작성**: 제공된 템플릿의 `init` 블록(다크모드)과 색상 변수 유지
3. **검증**: `/mermaid validate [file]` 명령어로 문법 및 규칙 위반 확인

## 2. 필수 준수 사항

1. **테마 통일**: 모든 다이어그램은 `/mermaid` 스킬이 제공하는 `init` 블록으로 시작해야 함
2. **줄바꿈 처리**: 노드 텍스트 내 줄바꿈은 `\n` 대신 `<br/>` 태그 사용
3. **코드 펜스**: 반드시 ```` ```mermaid ```` 로 감싸기
4. **설명 추가**: Human 대상 문서는 다이어그램 하단에 `노드 설명 테이블` 포함

## 3. 도움말

- 상세 문법 및 예시: `/mermaid examples`
- 색상 팔레트 확인: `/mermaid palette`


---
autovibe: true
type: rule
version: "1.0"
created: "2026-02-24"
group: base
name: av-base-memory-first
description: 에이전트 유형별 메모리 검색 전략 및 콘텐츠 저장 위치 정책
---

# Memory Strategy — 에이전트 유형별 전략

> 에이전트 종류에 따라 다른 메모리 접근 전략을 사용한다.
> 전체 태그 체계: `docs/reference/mcp-tags.md` 참조

## 에이전트 유형별 검색 우선순위

### Type A: MCP 접근 가능
**(메인 세션, general-purpose, Explore, av- 에이전트)**

1. **MCP Memory** (localhost:9095) — 문서/설계 명세/장기 지식 검색
2. **로컬 MEMORY.md** — 에이전트 고유 패턴 (즉시 로드)
3. **Glob/Grep** — 코드 탐색
4. **웹** — 외부 정보

### Type B: MCP 접근 불가
**(bkit 에이전트 전체: gap-detector, pdca-iterator, code-analyzer, report-generator 등)**

1. **로컬 MEMORY.md** — 에이전트 고유 패턴 (즉시)
2. **Glob/Grep** — 코드 탐색
3. **컨텍스트 전달 받기** — 파일경로 + 1줄 요약 (≤2K자)

> **중요**: bkit 에이전트는 MCP 검색 시도 자체를 하지 않는다 (항상 실패함).

## 콘텐츠 저장 위치 정책 (SOT)

| 정보 유형 | 저장 위치 | 중복 저장 |
|---------|---------|:--------:|
| **알려진 버그** (Known Bugs) | 글로벌 MEMORY.md만 | **금지** |
| **프로젝트 전체 패턴** | MCP Memory (docs/ sync) | — |
| **에이전트 고유 패턴** | 에이전트 MEMORY.md | — |
| **스킬 설정값** | 스킬 MEMORY.md | — |
| **PDCA 이력** | 글로벌 MEMORY.md (최근 5) + docs/ | — |
| **설계 명세/API 스펙** | MCP Memory | — |
| **에이전트 작업 이력** | 에이전트 MEMORY.md (최근 3건) | — |

## MEMORY.md 크기 기준

| 계층 | 기준 | 초과 시 조치 |
|------|------|-----------|
| 에이전트 MEMORY.md | **≤ 30줄** | 오래된 이력 삭제 |
| 스킬 MEMORY.md | **≤ 20줄** | 빈 섹션 제거 |
| 글로벌 MEMORY.md | **≤ 2,000 토큰** | PDCA 최근 5개 유지 |

## MCP 핵심 태그 (Type A 에이전트용)

```bash
search_by_tag("scope:erp")      # ERP SaaS (TO-BE)
search_by_tag("scope:legacy")   # 레거시 Java ERP
search_by_tag("scope:alli")     # AI ERP 모노레포
search_by_tag("scope:meta")     # PDCA 문서/설정
search_by_tag("service:acc")    # 특정 서비스
search_by_tag("type:pdca-plan") # PDCA 계획서
```

## 컨텍스트 전달 형식 (bkit 에이전트)

```
[파일경로] 1줄 요약 (≤2K자)
예: docs/02-design/features/auth.design.md — JWT + Supertokens 인증 설계 명세
```

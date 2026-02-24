---
title: AutoVibe 생태계 개발자 문서
description: AutoVibe(av-) 생태계 전체 인덱스 + 개요 + Quick Reference
created: "2026-02-24"
---

# AutoVibe 생태계 — 개발자 문서

> 이 문서는 AutoVibe(av-) 생태계의 개발자 진입점이다.
> 새 컴포넌트를 만들거나 기존 컴포넌트를 이해하려는 개발자를 위한 가이드.

---

## AutoVibe란?

**AutoVibe**는 Claude Code 위에서 동작하는 자기 성장 AI 생태계다.

```
핵심 개념:
  av- 접두사로 시작하는 모든 컴포넌트(Skill/Agent/Hook/Rule)가 생태계를 구성.
  새 컴포넌트는 /av-vibe-forge로만 생성 → components.json에 자동 등록.
  /av 게이트웨이가 자연어를 분석해 최적 컴포넌트를 자동 선정·실행.
  작업 완료 후 av-base-auditor가 자동 감사 → 학습 내용이 MEMORY.md에 누적.
  이 사이클이 반복되면서 생태계가 성장한다.
```

**현황** (2026-02-24 기준, `components.json` v3.2 — 도메인 기반 체계):

| 도메인 | 유형 | 수량 | 이식 |
|--------|------|:----:|:----:|
| vibe | Skill+Agent | 9개 | 항상 |
| base | Skill+Agent+Hook+Rule | 21개 | 항상 |
| util | Skill+Rule | 7개 | 선택 |
| erp/do/legacy | 전체 유형 | 43개 | 제외 |
| **합계** | | **80개** | |

**이식 패키지** (portable): 36개 (vibe 9 + base 21 + util 6)

---

## 문서 목차

| 문서 | 용도 | 대략 분량 |
|------|------|---------|
| **README.md** (이 파일) | 인덱스 + 개요 + Quick Reference | ~100줄 |
| **architecture.md** | 3-Layer 구조, Registry, OOP 상속, 위임 패턴, Hook 이벤트 사이클 | ~300줄 |
| **component-types.md** | Skill/Agent/Hook/Rule 유형별 frontmatter, 구조, 실제 예시 | ~300줄 |
| **execution-flow.md** | 전체 실행 흐름, 시작/종료 프로토콜, 메모리 4계층, 감사 시스템 | ~250줄 |
| **dev-guide.md** | 새 컴포넌트 만드는 법, ROUTING_TABLE 확장, 검증 체크리스트 | ~250줄 |

### 관련 스펙 문서 (topics/)

| 문서 | 내용 | 경로 |
|------|------|------|
| Frontmatter Spec | 유형별 필수/선택 필드 전체 | `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md` |
| Naming Rules | av- 접두사, 그룹, OOP 상속, 공존 규칙 | `.claude/docs/av-claude-code-spec/topics/naming-rules.md` |
| Protocols | 시작/종료 프로토콜, 보고서 형식, 버전 관리 | `.claude/docs/av-claude-code-spec/topics/protocols.md` |
| Audit Rules | 계층별 감사, 셀프 체크, 면제 규칙 | `.claude/docs/av-claude-code-spec/topics/audit-rules.md` |

---

## 3-Layer 구조 한눈에 보기

```
Layer 3 (User Gateway):  /av
                          ↓ 자연어 → ROUTING_TABLE → 컴포넌트 선정 → 위임 실행

Layer 2 (Domain):         av-do-orchestrator, av-erp-migration, av-legacy-blueprint,
                          av-base-code-quality, av-base-git-commit, av-base-refactor, av-base-auditor ...
                          (70+ 도메인 전문 컴포넌트)

Layer 1 (Meta):           av-vibe-forge (컴포넌트 생성/관리)
                          av-vibe-portable-init (이식 초기화)
                          av-vibe-migrator (레거시 마이그레이션)
```

---

## Quick Reference — 주요 명령어 5개

### 1. 자연어로 최적 컴포넌트 실행

```bash
/av run {자연어 요구사항}

# 예시
/av run acc 백엔드 구현
/av run 레거시 acc/bdg/AR1001 설계문서 생성
/av run {{BACKEND_FRAMEWORK}} 코드 품질 검사
```

### 2. 새 컴포넌트 생성

```bash
/av-vibe-forge skill {name} --group {group}   # 새 스킬
/av-vibe-forge agent {name} --group {group} --inherits av-base-auditor  # 상속 에이전트
/av-vibe-forge hook PostToolUse {name}         # 새 훅
/av-vibe-forge rule {name}                     # 새 룰
```

### 3. 생태계 건강도 확인

```bash
/av-vibe-forge health
# 또는
/av health
```

### 4. 컴포넌트 검증

```bash
/av-vibe-forge validate               # 전체 검증
/av-vibe-forge validate av-{name}     # 특정 컴포넌트
/av-vibe-forge tree                   # 상속 트리 시각화
```

### 5. 다른 프로젝트로 이식

```bash
# 현재 프로젝트에서 이식 패키지 생성
/av-vibe-forge export --portable

# 대상 프로젝트에서 이식
/av-vibe-portable-init setup
```

---

## 도메인별 주요 컴포넌트

```
av-vibe-* — 생태계 핵심 도구 (항상 이식)
  /av                     마스터 게이트웨이
  /av-vibe-forge          컴포넌트 생성/관리 오케스트레이터 (14 서브커맨드)
  /av-vibe-portable-init  다른 프로젝트로 원클릭 이식
  /av-vibe-migrator       레거시 구성요소 → av- 생태계 마이그레이션

av-base-* — 범용 필수 도구 (항상 이식)
  av-base-auditor         감사 에이전트 (L1~L3 셀프/표준/구조 감사)
  /av-base-code-quality   코드 품질 게이트 ({{LINTER_NAME}}+TS+Jest+Build)
  /av-base-git-commit     git 커밋 자동화 (Conventional Commits)
  /av-base-sync           CLAUDE.md 자동 최신화
  /av-base-refactor       리팩토링 오케스트레이터

av-util-* — 범용 선택 도구 (기술스택 맞으면 이식)
  /av-util-redis          Redis 조회/관리
  /av-util-shadcn         shadcn/ui 레퍼런스 ({{FRONTEND_FRAMEWORK}} 전용)
  /av-util-mermaid        Mermaid 다이어그램 표준

av-erp-* / av-do-* / av-legacy-* — 프로젝트 전용 (이식 제외)
  /av-do-orchestrator     설계MD → DB+API+Backend+Frontend 파이프라인
  /av-erp-migration       레거시 Java → {{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}} 전환
  /av-legacy-blueprint    프로그램 ID 단위 설계문서 생성
  av-erp-backend-guard    {{BACKEND_FRAMEWORK}}/{{ORM_NAME}} 패턴 감시
  av-erp-frontend-guard   Frontend 품질 감시 (3 자식)
```

---

## 핵심 파일 경로

| 파일 | 역할 |
|------|------|
| `.claude/registry/components.json` | 전체 80개 컴포넌트 SSOT |
| `.claude/skills/av/SKILL.md` | Gateway 라우팅 로직 + ROUTING_TABLE |
| `.claude/skills/av-vibe-forge/SKILL.md` | 14개 서브커맨드 구조 |
| `.claude/agents/av-base-auditor.md` | 감사 체크리스트 |
| `.claude/settings.json` | Hook 등록 구조 |
| `.claude/docs/av-portable-guide.md` | 이식 완전 가이드 |

---

> Claude는 완벽하지 않습니다. 중요한 결정은 항상 확인하세요.

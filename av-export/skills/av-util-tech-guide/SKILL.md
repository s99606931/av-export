---
name: av-util-tech-guide
description: "신규 개발자용 기술 스택/아키텍처/용어 학습 가이드 생성"
argument-hint: "[generate|glossary|roadmap] [topic]"
user-invocable: true
allowed-tools: Read,Write,Edit,Glob,Grep,WebSearch
autovibe: true
version: "1.0"
created: "2026-02-24"
group: base
tier: null
inherits: null
---

# Tech Learning Guide Gen 스킬

> 신규 개발자를 위한 프로젝트 기술 스택, 아키텍처, 전문 용어 학습 가이드를 생성합니다.

## 가이드 작성 원칙

### 대상 (Audience)
- **신규 입사자 (Junior/Newcomer)**: 프로젝트의 전체적인 맥락을 모르는 상태에서 기술적 기초를 다지는 개발자.

### 작성 스타일
- **Easy to Understand**: 추상적인 개념보다는 비유와 실제 프로젝트 코드를 예시로 설명.
- **Visual First**: 모든 아키텍처 설명은 Mermaid 다이어그램을 포함.
- **Atomic Content**: 한 파일이 너무 길지 않도록 주제별로 분리하여 생성 (AI가 한 번에 출력하기 적당한 200~400줄 내외).

### 필수 구성 요소
1. **Mermaid 다이어그램**: 구조적 이해를 돕기 위한 시각화.
2. **용어 설명 테이블**: 전문 용어에 대한 명확한 정의.
3. **핵심 파일 경로**: 해당 기술이 실제로 적용된 프로젝트 내 위치 안내.

## 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `generate [topic]` | 특정 주제별 학습 가이드 생성 | `/tech-learning-guide-gen generate architecture` |
| `glossary` | 프로젝트 전문 용어 사전 생성 | `/tech-learning-guide-gen glossary` |
| `roadmap` | 신규 개발자 온보딩 로드맵 생성 | `/tech-learning-guide-gen roadmap` |

## 명령어 상세

### generate [topic]

주제별 가이드 구성:

- **architecture**: 프로젝트의 전체적인 구조 (Microservices, Monorepo, MCP 등).
- **frontend**: {{FRONTEND_FRAMEWORK}}, React Query, Tailwind CSS, Shadcn/UI 등 프론트엔드 스택.
- **backend**: {{BACKEND_FRAMEWORK}}, {{ORM_NAME}}, PostgreSQL, {{MESSAGING_SYSTEM}} 등 백엔드 및 인프라 스택.
- **vibe-coding**: Claude Code, Gemini CLI 등을 활용한 프로젝트 특유의 개발 방식.

### glossary

- 프로젝트 내에서 사용하는 도메인 용어 및 기술 약어 정리.
- 예: MCP (Model Context Protocol), PDCA (Plan-Do-Check-Act), BaaS (Backend as a Service) 등.

### roadmap

- 1주차 ~ 4주차 단계별 학습 목표 및 실습 과제 제시.

## Mermaid 다이어그램 표준

> **`/mermaid` 스킬 표준 준수** — 다크모드 init 블록, 색상 팔레트, 오류 방지 10규칙, 다이어그램 유형별 템플릿 참조.

## 출력 디렉토리

- `docs/guides/onboarding/` 내에 생성.

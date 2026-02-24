---
name: av-util-shadcn
description: "shadcn/ui v4 컴포넌트 레퍼런스 스킬 - shadcn-ui MCP (8 도구) 대체"
argument-hint: "[component|block|list|theme|install] [component-name]"
user-invocable: true
allowed-tools: WebFetch,WebSearch,Bash,Read
autovibe: true
version: "1.0"
created: "2026-02-24"
group: base
tier: null
inherits: null
---

# Shadcn Ref 스킬

> WebFetch + `npx shadcn@latest` CLI로 shadcn/ui v4 컴포넌트를 조회합니다.
> **대체 대상**: shadcn-ui MCP (8 MCP 도구) → 이 스킬 1개

## 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `component [name]` | 컴포넌트 소스코드 조회 | `/shadcn-ref component button` |
| `block [name]` | 블록 소스코드 조회 | `/shadcn-ref block dashboard-01` |
| `list` | 전체 컴포넌트 목록 | `/shadcn-ref list` |
| `list blocks` | 전체 블록 목록 | `/shadcn-ref list blocks` |
| `theme [name]` | 테마 적용 방법 | `/shadcn-ref theme cyberpunk` |
| `install [name]` | 설치 명령어 출력 | `/shadcn-ref install button` |
| `metadata [name]` | 컴포넌트 메타정보 | `/shadcn-ref metadata button` |

## 조회 방법

### component — 컴포넌트 소스
```
GitHub 소스코드 직접 조회:
https://raw.githubusercontent.com/shadcn-ui/ui/main/registry/ui/{component}.json
```

WebFetch URL 패턴:
```
https://ui.shadcn.com/docs/components/{component}
```

### list — 컴포넌트 목록
```
https://ui.shadcn.com/docs/components
```

### block — 블록 소스
```
https://ui.shadcn.com/blocks
https://raw.githubusercontent.com/shadcn-ui/ui/main/registry/blocks/{block}.json
```

## CLI 설치 명령어 패턴

```bash
# 단일 컴포넌트 설치
npx shadcn@latest add {component-name}

# 예시
npx shadcn@latest add button
npx shadcn@latest add dialog
npx shadcn@latest add data-table
npx shadcn@latest add form
```

## {{PROJECT_NAME}} UI 패키지 위치

```
{{PROJECT_SRC}}/packages/ui/
├── src/components/        # shadcn 래퍼 컴포넌트
├── registry.json          # UI 레지스트리
└── package.json
```

## 컴포넌트 설치 위치

```
{{PROJECT_SRC}}/packages/ui/src/components/{component}/
```

## 자주 사용하는 컴포넌트

| 컴포넌트 | 용도 | {{PROJECT_NAME}} 사용처 |
|----------|------|---------------|
| `button` | 버튼 | 전체 폼 |
| `dialog` | 모달 | 등록/수정 폼 |
| `data-table` | 데이터 그리드 | 목록 화면 |
| `form` | 폼 | 입력 화면 |
| `select` | 드롭다운 | 코드 선택 |
| `calendar` | 날짜 선택 | 날짜 입력 |
| `tabs` | 탭 | 상세 화면 |
| `sidebar` | 사이드바 | 앱 셸 |
| `chart` | 차트 | 대시보드 |
| `badge` | 뱃지 | 상태 표시 |

## v4 주요 변경사항 (Tailwind CSS 4.1)

- CSS 변수 기반 테마 시스템 (`:root` + `oklch`)
- `cn()` 유틸리티 필수
- 신규 컴포넌트: `sidebar`, `chart`, `calendar`
- 디렉토리: `components/ui/` (기존과 동일)

ARGUMENTS: [component|block|list|theme|install|metadata] [name]

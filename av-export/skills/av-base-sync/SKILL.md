---
name: av-base-sync
description: |
  Claude Code 세션에서 프로젝트 내 모든 CLAUDE.md를 스캔하여 자동 최신화하는 스킬.
  루트부터 packages, shell, 그리고 모든 마이크로서비스의 backend/frontend CLAUDE.md까지
  실제 코드베이스와 비교하여 오래된 정보를 탐지하고 업데이트. 파일이 없으면 자동 생성.
  트리거: claude.md 최신화, docs-sync, CLAUDE.md 업데이트, 환경 동기화, sync claude
autovibe: true
version: "3.1"
created: "2026-02-22"
group: base
tier: null
inherits: null
argument-hint: "[discover|scan|diff|update|generate|status] [--target root|svc:cmm|svc:cmm/backend|svc:core|svc:all|all|...]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, Task]
---

# av-base-sync v3.0 — 전체 계층 CLAUDE.md 자동 최신화

> 루트({{PROJECT_NAME}}) → ERP 모노레포 → 패키지 → 모든 마이크로서비스(backend+frontend) 단위까지
> 실제 코드베이스 스캔 기반 자동 생성·업데이트 지원.

## Arguments

| 인자 | 필수 | 설명 | 기본값 |
|------|:----:|------|--------|
| `command` | ✅ | 실행할 서브커맨드 | `status` |
| `--target` | ❌ | 대상 CLAUDE.md (아래 타겟 ID 참조) | `root` |

## Subcommands

| 명령어 | 설명 |
|--------|------|
| `discover [--services]` | 모든 CLAUDE.md 목록 + 신선도. `--services`는 서비스 레벨만 |
| `status [--target]` | 대상 신선도 빠른 확인 |
| `scan [--target]` | 대상 환경 전체 스캔 보고서 |
| `diff [--target]` | 대상 CLAUDE.md vs 실제 코드 비교 |
| `update [--target]` | CLAUDE.md 자동 업데이트 (없으면 자동 생성) |
| `generate [--target]` | 강제 신규 생성 (기존 파일 덮어쓰기) |

---

## 타겟 ID 체계

### 레벨 1: 글로벌 + 패키지 타겟

| 타겟 ID | CLAUDE.md 경로 | 전략 |
|---------|----------------|------|
| `root` | `{{PROJECT_ROOT}}/CLAUDE.md` | 스킬/에이전트/버전/page.tsx/AutoVibe |
| `erp-src` | `{{PROJECT_SRC}}/CLAUDE.md` | 서비스 목록, 모듈 구조 |
| `packages/ui` | `{{PROJECT_SRC}}/packages/ui/CLAUDE.md` | 컴포넌트 목록 |
| `packages/common` | `{{PROJECT_SRC}}/packages/common/CLAUDE.md` | Export 목록 |
| `packages/api-client` | `{{PROJECT_SRC}}/packages/api-client/CLAUDE.md` | 훅/클라이언트 |
| `shell` | `{{PROJECT_SRC}}/shell/frontend/CLAUDE.md` | page.tsx 수, Known Gaps |
| `services/ai` | `{{PROJECT_SRC}}/services/ai/CLAUDE.md` | AI 서비스 목록 |

### 레벨 2: 서비스 타겟 (`svc:` 프리픽스)

> `svc:{code}` = backend + frontend 동시. 없는 CLAUDE.md는 자동 생성.

| 타겟 패턴 | 대상 |
|----------|------|
| `svc:{code}` | 특정 서비스 backend + frontend |
| `svc:{code}/backend` | 특정 서비스 backend만 |
| `svc:{code}/frontend` | 특정 서비스 frontend만 |
| `svc:core` | core 7개 서비스 전체 |
| `svc:extended` | extended 8개 서비스 전체 |
| `svc:platform` | platform 서비스 전체 |
| `svc:all` | 모든 마이크로서비스 전체 |

**서비스 코드 목록 (SSOT §3 기준):**

| 카테고리 | 서비스 코드 | 설명 |
|---------|-----------|------|
| core | sys, cmm, acc, bdg, slip, pay, hcm | 핵심 업무 7개 |
| extended | tax, ast, gds, ctr, elc, grf, lnk, itf | 확장 업무 8개 |
| platform | auth, tenant, notification, feedback, audit, billing, archive, mcp-server | 플랫폼 8개 |

### 레벨 3: 전체 타겟

| 타겟 ID | 설명 |
|---------|------|
| `all` | 글로벌+패키지 타겟 전체 (레벨1) |
| `svc:all` | 모든 서비스 CLAUDE.md (레벨2) |
| `everything` | 레벨1 + 레벨2 전체 |

---

## 시작 프로토콜

```
STEP 1: Read .claude/skills/av-base-sync/MEMORY.md → 이전 스캔 결과 확인
STEP 2: 서브커맨드 + --target 파싱
STEP 3: 타겟 타입 분류:
   - 'svc:' 프리픽스 → 서비스 레벨 흐름 (아래 §서비스 Sync 프로필)
   - 그 외 → 레벨1 흐름 (아래 §레벨1 타겟별 Sync 프로필)
STEP 4: 실행
```

---

## discover [--services]

```
1. Glob {{PROJECT_ROOT}}/**/CLAUDE.md (node_modules 제외)
2. --services 없음: 전체 목록 출력
3. --services: 서비스 레벨만 필터
   → services/{category}/{svc-name}/{backend|frontend}/CLAUDE.md 패턴

출력 형식:
## 프로젝트 CLAUDE.md 파일 현황

### 레벨1 (글로벌+패키지)
| 타겟 ID | 경로 | 상태 |
|---------|------|------|
| root | CLAUDE.md | ✅ 최신 |
| packages/ui | packages/ui/CLAUDE.md | ✅ 최신 |
...

### 레벨2 (마이크로서비스)
| 서비스 | backend | frontend |
|--------|---------|---------|
| sys-service | ✅ 있음 | ✅ 있음 |
| cmm-service | ❌ 없음 | ❌ 없음 |
| ast-service | ❌ 없음 | ✅ 있음 |
...

→ 생성 필요: `/av-base-sync generate --target svc:all`
```

---

## §레벨1 타겟별 Sync 프로필 (기존 v2.0 유지)

### root, erp-src, packages/ui, packages/common, packages/api-client, shell, services/ai

> v2.0 프로필 그대로 유지. 변경 없음.

#### 타겟: `root` — 루트 CLAUDE.md
```
1. Glob .claude/skills/*/SKILL.md → user-invocable: true 스킬 목록
2. Glob .claude/agents/*.md → 에이전트 목록
3. Read .claude/registry/components.json → autovibe: true 컴포넌트
4. Glob {{PROJECT_SRC}}/shell/frontend/src/app/**/page.tsx → page.tsx 수
5. Read {{PROJECT_SRC}}/package.json → {{PKG_MANAGER}}, {{LINTER_NAME}} 버전
diff: Skills 테이블 / AutoVibe 테이블 / page.tsx 수 / 기술 스택 버전
```

#### 타겟: `packages/ui`
```
1. Glob {{PROJECT_SRC}}/packages/ui/src/components/*/index.ts → 컴포넌트 목록
2. CLAUDE.md "컴포넌트 목록 (N개)" 헤더 수 비교
diff: 신규 컴포넌트 [MISSING] / 삭제 컴포넌트 [GHOST]
```

#### 타겟: `packages/common`
```
1. Read {{PROJECT_SRC}}/packages/common/src/index.ts → export 카테고리 목록
diff: 신규 카테고리 / 삭제 카테고리 / 변경된 export
```

#### 타겟: `packages/api-client`
```
1. Glob {{PROJECT_SRC}}/packages/api-client/src/hooks/use-*.ts → 훅 목록
diff: 신규 훅 [MISSING] / 삭제 훅 [GHOST]
```

#### 타겟: `shell`
```
1. find .../shell/frontend/src/app -name "page.tsx" | wc -l → page.tsx 수
2. find ... -name "loading.tsx" | wc -l → loading.tsx 수
3. find ... -name "error.tsx" | wc -l → error.tsx 수
diff: Known Gaps 테이블 수치 불일치
```

---

## §서비스 Sync 프로필 (v3.0 신규)

> `svc:{code}` 타겟 처리 핵심 로직.
> **generate 모드**: CLAUDE.md 없음 → SERVICE.md + src/ 스캔으로 신규 생성
> **update 모드**: CLAUDE.md 있음 → 실제 코드와 비교 후 차이만 업데이트

### 서비스 경로 해석 규칙

```
svc:{code} 입력 시:
1. services/core/{code}-service/ 검색 → 있으면 core
2. services/extended/{code}-service/ 검색 → 있으면 extended
3. services/platform/{code}/ 검색 → 있으면 platform
4. 없으면 오류 출력

결정된 경로:
  svc_root = services/{category}/{code}[-service]/
  backend_path = {svc_root}backend/
  frontend_path = {svc_root}frontend/  (없으면 skip)
```

### 서비스 Backend CLAUDE.md 생성/업데이트

#### generate 모드 (신규 생성)

```
입력: SERVICE.md + backend/src/ 스캔

STEP 1: Read {svc_root}/SERVICE.md
  → 서비스명, 포트, 설명, API 엔드포인트, {{ORM_NAME}} 모델, {{MESSAGING_SYSTEM}} 이벤트, 환경변수 추출

STEP 2: ls {backend_path}src/ → 도메인 디렉토리 목록
  → 각 도메인: {domain}.module.ts 존재 확인

STEP 3: Read {backend_path}package.json → 패키지명 추출

STEP 4: Write {backend_path}CLAUDE.md (아래 템플릿)
```

**Backend CLAUDE.md 생성 템플릿:**

```markdown
# CLAUDE.md - {code}-service/backend

<!-- 역할: {svc_name} {{BACKEND_FRAMEWORK}} 백엔드 전용 컨텍스트. 도메인 모듈 구조, API 설계, {{ORM_NAME}} 규칙. -->

> **바이브 코딩 컨텍스트** — {svc_name} Backend ({{BACKEND_FRAMEWORK}} + Fastify)

## 메타
| 항목 | 값 |
|------|-----|
| 패키지명 | `{package_name}` |
| 경로 | `{{PROJECT_SRC}}/{svc_root}backend/` |
| 포트 | {be_port} |
| 규칙 | `prisma7-conventions`, `nestjs-fastify-patterns`, `api-design-standards` |

## 도메인 모듈

| 도메인 | 경로 | 설명 |
|--------|------|------|
{domain_rows}

## API 엔드포인트 (SERVICE.md 기준)

{api_endpoints_table}

## {{ORM_NAME}} 모델

{prisma_models_list}

## {{MESSAGING_SYSTEM}} 이벤트

{nats_events_list}

## 환경변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
{env_vars_table}

## 개발 명령어

```bash
{{PKG_MANAGER}} --filter {package_name} dev
{{PKG_MANAGER}} --filter {package_name} test
```

> SSOT §3 참조 | 공통 패턴: `{{PACKAGE_SCOPE}}/common`
```

#### update 모드 (기존 파일 업데이트)

```
STEP 1: Read {backend_path}CLAUDE.md → 현재 내용 파악
STEP 2: ls {backend_path}src/ → 실제 도메인 목록 vs CLAUDE.md 도메인 테이블 비교
STEP 3: Read SERVICE.md → API 엔드포인트 최신 여부 확인
STEP 4: 차이 항목만 Edit
  - 신규 도메인 행 추가
  - 삭제된 도메인 행 제거
  - API 엔드포인트 수 변경 시 업데이트
```

---

### 서비스 Frontend CLAUDE.md 생성/업데이트

> frontend/ 디렉토리가 없는 서비스(archive 등)는 skip.

#### generate 모드 (신규 생성)

```
STEP 1: Read {svc_root}/SERVICE.md → 서비스명, FE 포트 추출
STEP 2: find {frontend_path}src/app -name "page.tsx"
  → 경로에서 라우트 경로 추출 (locale strip 후)
STEP 3: Read {frontend_path}package.json → 패키지명
STEP 4: Write {frontend_path}CLAUDE.md (아래 템플릿)
```

**Frontend CLAUDE.md 생성 템플릿:**

```markdown
# CLAUDE.md - {code}-service/frontend

<!-- 역할: {svc_name} {{FRONTEND_FRAMEWORK}} 프론트엔드 전용 컨텍스트. 라우트 구조, 컴포넌트 패턴. -->

> **바이브 코딩 컨텍스트** — {svc_name} Frontend ({{FRONTEND_FRAMEWORK}} 15)

## 메타
| 항목 | 값 |
|------|-----|
| 패키지명 | `{fe_package_name}` |
| 경로 | `{{PROJECT_SRC}}/{svc_root}frontend/` |
| 포트 | {fe_port} |
| 규칙 | `frontend-nextjs-rules`, `biome-lint-rules` |

## 라우트 구조

| 경로 | 설명 |
|------|------|
{route_rows}

## 훅 임포트

```typescript
import { use{Code} } from '{{PACKAGE_SCOPE}}/api-client';
```

## 개발 명령어

```bash
{{PKG_MANAGER}} --filter {fe_package_name} dev
```

> 공유 컴포넌트: `{{PACKAGE_SCOPE}}/ui` | 페이지 템플릿: `ListGrid`, `EntryForm` 등
```

#### update 모드 (기존 파일 업데이트)

```
STEP 1: Read {frontend_path}CLAUDE.md → 현재 라우트 목록 파싱
STEP 2: find {frontend_path}src/app -name "page.tsx" → 실제 라우트 목록
STEP 3: 신규/삭제 라우트 감지
STEP 4: Edit CLAUDE.md 라우트 테이블 업데이트
```

---

## §카테고리 타겟 실행 순서

### `svc:core`
```
순서: sys → cmm → acc → bdg → slip → pay → hcm
각 서비스: generate or update (backend + frontend)
```

### `svc:extended`
```
순서: tax → ast → gds → ctr → elc → grf → lnk → itf
```

### `svc:platform`
```
순서: auth → tenant → notification → feedback → audit → billing → archive → mcp-server
```

### `svc:all`
```
순서: platform → core → extended
완료 후 통합 보고서 출력:
## 서비스 CLAUDE.md 업데이트 결과
| 서비스 | backend | frontend | 모드 |
|--------|---------|---------|------|
| cmm | ✅ 생성 | ✅ 생성 | generate |
| ast | ✅ 생성 | ✅ 생성 | generate |
...
```

---

## §업데이트 안전 규칙

```
1. 서비스 CLAUDE.md: 100줄 이내 권장 (간결 유지)
2. SERVICE.md → Single Source of Truth (포트, API 등은 SERVICE.md 기준)
3. 서비스 없으면 skip + 경고 출력 (오류 아님)
4. frontend 디렉토리 없으면 backend만 처리
5. 한국어 유지
6. generate 후 반드시 Read로 검증
7. node_modules 제외
```

---

## 사용 예시

```bash
# 전체 현황 보기
/av-base-sync discover

# 서비스 레벨만 현황 보기
/av-base-sync discover --services

# 특정 서비스 backend+frontend 생성
/av-base-sync generate --target svc:cmm
/av-base-sync generate --target svc:ast
/av-base-sync generate --target svc:archive

# 특정 서비스 backend만
/av-base-sync generate --target svc:cmm/backend

# 카테고리 전체 생성
/av-base-sync generate --target svc:core
/av-base-sync generate --target svc:extended
/av-base-sync generate --target svc:platform

# 모든 서비스 한번에
/av-base-sync generate --target svc:all

# 기존 서비스 CLAUDE.md 업데이트 (신규 도메인/라우트 반영)
/av-base-sync update --target svc:cmm

# 레벨1+레벨2 전체
/av-base-sync update --target everything

# 기존 레벨1 전체 (패키지+루트)
/av-base-sync update --target all
```

---

## 종료 프로토콜

```
update / generate 명령 완료 시:
  STEP 1: 자신의 MEMORY.md 업데이트 (스캔 결과, 변경 파일 목록)
  STEP 2: CLAUDE.md 변경 포함 시 → av-base-sync-auditor 에이전트 호출
    Task("av-base-sync-auditor", {
      changed_files: [변경된 CLAUDE.md 경로 목록],
      task: "CLAUDE.md 동기화 후 정합성 검증",
      requester: "av-base-sync"
    })
  STEP 3: auditor PASS → 종료
          auditor FAIL → 피드백 반영 후 재수정 (최대 1회)

discover / status / diff 명령:
  → 파일 미변경 → L1 Self-Check만 (MEMORY.md 업데이트)
```

## 참조

| 파일 | 용도 |
|------|------|
| `{{PROJECT_SRC}}/SSOT.md` | 서비스 목록, 포트 정보 (§3) |
| `{svc_root}/SERVICE.md` | 서비스 메타 (API, {{ORM_NAME}}, {{MESSAGING_SYSTEM}}, 환경변수) |
| `{svc_root}/backend/src/` | 실제 도메인 모듈 디렉토리 |
| `{svc_root}/frontend/src/app/` | 실제 페이지 라우트 |
| `.claude/registry/components.json` | AutoVibe 컴포넌트 레지스트리 |
| `av-base-sync-auditor` 에이전트 | CLAUDE.md 정합성 감사 — update/generate 후 자동 호출 |

## 실행 프로토콜 참조

- 시작/종료 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`

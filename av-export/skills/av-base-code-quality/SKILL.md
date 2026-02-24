---
name: av-base-code-quality
description: |
  개발 완료 후 실행하는 코드 품질 게이트 스킬. {{LINTER_NAME}} lint/format,
  TypeScript typecheck, Jest test, {{MONOREPO_TOOL}} build 검사를 단계별로 실행.
  자동 수정 지원 및 구조화 보고서 출력.
  트리거: 개발 완료, lint, format, typecheck, build, code quality, 품질 검사, 문법 검사
autovibe: true
version: "1.1"
created: "2026-02-22"
group: base
tier: null
inherits: null
argument-hint: "[check|lint|format|typecheck|test|build|fix|all] [서비스명?]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit, Task]
---

# av-base-code-quality — 코드 품질 게이트 스킬

> 개발 완료 후 필수적으로 실행하는 Post-Development Quality Gate.
> {{LINTER_NAME}}(lint/format) → TypeScript(typecheck) → Jest(test) → Build 순서로 검사 후 자동 수정.

## Arguments

| 인자 | 필수 | 설명 | 기본값 |
|------|:----:|------|--------|
| `command` | ✅ | 실행할 검사 명령어 | `check` |
| `서비스명` | ❌ | 특정 서비스만 대상 (없으면 전체 모노레포) | — |

## Subcommands

| 명령어 | 설명 | 자동 수정 |
|--------|------|:---------:|
| `check` | lint + format + typecheck 검사만 (수정 없음) | ❌ |
| `lint` | {{LINTER_NAME}} 린트 검사 + 자동 수정 | ✅ |
| `format` | {{LINTER_NAME}} 포맷 정리 + 자동 수정 | ✅ |
| `typecheck` | TypeScript 타입 검사 + 오류 수정 가이드 | 부분 |
| `test` | Jest 단위 테스트 실행 + 실패 분석 | 부분 |
| `build` | {{MONOREPO_TOOL}} 빌드 + 오류 수정 | 부분 |
| `fix` | lint + format 자동 수정 (unsafe 포함) | ✅ |
| `all` | check → lint → format → typecheck → test → build 전체 실행 | ✅ |

## 프로젝트 설정

```
루트 디렉토리: {{PROJECT_ROOT}}/{{PROJECT_SRC}}
린터: {{LINTER_NAME}} (not ESLint)
패키지 매니저: {{PKG_MANAGER}}
빌드 도구: {{MONOREPO_TOOL}} + Docker ({{BUILD_COMMAND}})
Node.js: 24.x LTS
```
> ⚠️ **빌드 환경 주의**: 컨테이너 개발 환경이므로 `{{PKG_MANAGER}} turbo run build` 직접 실행 금지.
> Docker 볼륨 마운트로 root 소유 파일이 생성되어 EACCES 오류 발생.
> 반드시 `{{BUILD_COMMAND}}` 또는 `{{PKG_MANAGER}} build` (동일 매핑) 사용.

---

## 실행 프로세스

### STEP 1: 환경 확인

```bash
cd {{PROJECT_ROOT}}/{{PROJECT_SRC}}
node --version   # 24.x LTS 필요
{{PKG_MANAGER}} --version   # 10.6.2 필요
```

---

### STEP 2: `check` — 검사 전용 (수정 없음)

```bash
# {{LINTER_NAME}} 린트 검사만
{{PKG_MANAGER}} biome check .

# TypeScript 타입 검사
{{PKG_MANAGER}} turbo run typecheck

# 빌드 검증 (dry-run)
{{BUILD_COMMAND}} --dry-run
```

결과를 요약 테이블로 출력 후 종료 (파일 수정 없음).

---

### STEP 3: `lint` — {{LINTER_NAME}} 린트

```bash
# 자동 수정 포함
{{PKG_MANAGER}} biome check --write .

# 특정 서비스
{{PKG_MANAGER}} turbo run lint --filter={{PACKAGE_SCOPE}}/{서비스명}
```

**자동 수정 항목**:
- `useConst`: `let` → `const`
- `noVar`: `var` → `const`/`let`
- import 정리: 미사용 import 제거, 정렬
- 세미콜론/따옴표 통일

**⚠️ 수동 수정 필요**:
- `noExplicitAny`: `any` → 구체적 타입
- `noUnusedVariables`: 미사용 변수 삭제 또는 `_` 접두어
- **{{BACKEND_FRAMEWORK}} DI CRITICAL**: `import type` → `import` (DI 파괴 방지)

---

### STEP 4: `format` — {{LINTER_NAME}} 포맷

```bash
# 포맷 적용
{{PKG_MANAGER}} biome format --write .

# 검사만 (수정 없음)
{{PKG_MANAGER}} biome format .
```

**biome.json 기준**:
- indent: 2 spaces | semicolons: always
- quotes: single | trailing commas: all

---

### STEP 5: `typecheck` — TypeScript 타입 검사

```bash
# 전체 타입 체크
{{PKG_MANAGER}} turbo run typecheck

# 특정 서비스
{{PKG_MANAGER}} turbo run typecheck --filter={{PACKAGE_SCOPE}}/{서비스명}

# 단일 서비스 직접
cd services/{category}/{service}/backend && npx tsc --noEmit
```

**오류 코드별 수정법**:

| 오류 코드 | 원인 | 수정법 |
|-----------|------|--------|
| TS2304 | 타입/인터페이스 없음 | import 추가 또는 타입 정의 |
| TS2345 | 타입 불일치 | 타입 캐스팅 또는 타입 수정 |
| TS2322 | 할당 타입 오류 | 타입 가드 추가 |
| TS2339 | 프로퍼티 없음 | 인터페이스에 프로퍼티 추가 |
| TS7006 | 암묵적 `any` | 명시적 타입 추가 |
| TS2769 | 오버로드 없음 | 정확한 파라미터 타입 지정 |

**{{BACKEND_FRAMEWORK}} DI 주의사항**:
```typescript
// ❌ import type → DI 파괴, TS 오류
import type { {{ORM_NAME}}Service } from './prisma.service';

// ✅ 일반 import 필수
import { {{ORM_NAME}}Service } from './prisma.service';
```

---

### STEP 6: `test` — Jest 단위 테스트

```bash
# 전체 테스트
{{PKG_MANAGER}} turbo run test

# 특정 서비스
{{PKG_MANAGER}} turbo run test --filter={{PACKAGE_SCOPE}}/{서비스명}

# passWithNoTests: 테스트 없는 서비스 통과
cd services/{category}/{service}/backend
{{PKG_MANAGER}} jest --passWithNoTests
```

**실패 원인 분류**:
- `Cannot find module` → import 경로 수정
- `is not a function` → mock 설정 확인
- `Expected ... but received` → 어설션 로직 수정
- `Timeout` → async/await 처리 확인

---

### STEP 7: `build` — Docker 컨테이너 빌드

> ⚠️ **컨테이너 환경**: `{{PKG_MANAGER}} turbo run build` 직접 사용 금지 (EACCES 권한 오류 발생).
> Docker 볼륨 마운트로 root 소유 파일이 생성되기 때문.
> 반드시 `{{BUILD_COMMAND}}` 사용 (UID 매핑 처리됨).

```bash
# 전체 빌드 (Docker UID 매핑, 권장)
cd {{PROJECT_ROOT}}/{{PROJECT_SRC}}
{{BUILD_COMMAND}}

# 또는 package.json 스크립트로 (동일 매핑: "build": "{{BUILD_COMMAND}}")
{{PKG_MANAGER}} build

# 특정 서비스 빌드
{{BUILD_COMMAND}} {서비스명}      # 예: {{BUILD_COMMAND}} acc

# 공유 패키지만 빌드
{{BUILD_COMMAND}} --packages

# 앱 셸만 빌드
{{BUILD_COMMAND}} --shell

# 캐시 없이 전체 빌드
{{BUILD_COMMAND}} --no-cache

# 빌드 명령 확인만 (실제 실행 안 함)
{{BUILD_COMMAND}} --dry-run

# {{ORM_NAME}} 스키마 변경 시 — generate 먼저, 그 후 빌드
cd services/{category}/{service}/backend
npx prisma generate
cd {{PROJECT_ROOT}}/{{PROJECT_SRC}}
{{BUILD_COMMAND}} {서비스명}
```

**빌드 실패 주요 원인**:

| 원인 | 진단 | 수정법 |
|------|------|--------|
| EACCES 권한 오류 | root 소유 파일 존재 | `{{BUILD_COMMAND}}` 사용 (직접 {{PKG_MANAGER}} turbo 금지) |
| {{ORM_NAME}} client 미생성 | `Cannot find module '../generated/prisma'` | `npx prisma generate` 후 재빌드 |
| 의존 패키지 미빌드 | `Cannot find module '{{PACKAGE_SCOPE}}/common'` | `{{BUILD_COMMAND}} --packages` 먼저 |
| lockfile 불일치 | `frozen-lockfile` 실패 | `{{PKG_MANAGER}} install --no-frozen-lockfile` 후 커밋 |
| TypeScript 오류 | 타입 에러 로그 | typecheck 단계 먼저 수행 |

**빌드 순서** (의존성):
```
packages/config → packages/common → packages/telemetry
  → packages/ui → packages/api-client
  → services/platform/* → services/core/*
  → services/extended/* → services/ai/*
  → shell/frontend
```

---

### STEP 8: `fix` — 자동 수정 (unsafe 포함)

```bash
# {{LINTER_NAME}} unsafe 수정 (의미 변경 가능 항목 포함)
{{PKG_MANAGER}} biome check --write --unsafe .
{{PKG_MANAGER}} biome format --write .
```

⚠️ `--unsafe` 플래그: 코드 의미를 변경할 수 있는 항목도 수정. 반드시 diff 확인 후 커밋.

---

### STEP 9: `all` — 전체 순차 실행

```
1. lint   → {{LINTER_NAME}} check --write (자동 수정)
2. format → {{LINTER_NAME}} format --write (자동 수정)
3. typecheck → tsc --noEmit (오류 시 보고)
4. test   → Jest (실패 시 원인 분석)
5. build  → Docker 컨테이너 빌드 {{BUILD_COMMAND}} (실패 시 원인 수정)
```

각 단계 결과를 누적하여 최종 리포트 출력.

---

## 최종 리포트 형식

```
# av-base-code-quality 품질 검사 결과

## 요약
| 항목       | 상태         | 세부 내용          |
|------------|------------|-------------------|
| lint       | ✅ PASS     | 자동 수정 N건       |
| format     | ✅ PASS     | 자동 수정 N건       |
| typecheck  | ⚠️ WARN     | 수동 수정 N건 필요  |
| test       | ✅ PASS     | N개 통과 / N개 건너뜀|
| build      | ✅ PASS     | -                 |

## 수동 수정 필요 항목
- [파일경로:라인] 오류 내용 → 수정 방법

## 전체 품질 점수: N/100

## 다음 단계
→ 모든 PASS 시: `git add && git commit` 준비 완료
→ WARN/FAIL 시: 위 항목 수정 후 재실행
```

---

## 종료 프로토콜

```
STEP 1: 자신의 MEMORY.md 업데이트 (실행 이력, 수정 파일 수)
STEP 2: 감사 레벨 결정
        - fix/lint/format/all 실행 후 파일 수정 있으면 → L2 av-base-auditor 감사 요청
          (changed_files: 자동 수정된 .ts/.tsx/.prisma 파일 목록)
        - check 명령어 (수정 없음) → L1 Self-Check만 수행

⚠️ av-base-quality-auditor 에이전트와의 역할 구분:
   - 이 스킬(av-base-code-quality): 사용자 직접 실행용 — 대화형 피드백 + 단계별 안내
   - av-base-quality-auditor 에이전트: 파이프라인 자동화용 — av-do-orchestrator 등 내부 호출
   두 컴포넌트는 동일 목적이나 사용 컨텍스트가 다름. 서로 호출 불필요.
```

## 참조

- `{{PROJECT_SRC}}/package.json` — 루트 스크립트
- `{{PROJECT_SRC}}/biome.json` — {{LINTER_NAME}} 린트/포맷 설정
- `.claude/rules/biome-lint-rules.md` — {{LINTER_NAME}} 규칙
- `.claude/rules/nestjs-di-import-rules.md` — DI import 규칙
- `.claude/rules/testing-standards.md` — 테스트 기준
- `av-erp-build-stabilizer` 에이전트 — 빌드 오류 자동 수정
- `av-base-quality-auditor` 에이전트 — 파이프라인 자동화 품질 검사 (av-do-orchestrator 연동)

## 실행 프로토콜 참조

- 시작/종료 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`

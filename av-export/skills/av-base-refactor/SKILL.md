---
name: av-base-refactor
description: |
  마이크로서비스 공통 모듈 추출 및 코드 재사용성 강화 리팩토링 스킬.
  중복 코드 탐지, 공통 패턴 분석, {{BACKEND_FRAMEWORK}}/{{FRONTEND_FRAMEWORK}} 리팩토링 플랜 자동 생성.
  트리거: refactor, 리팩토링, 중복 제거, 공통 모듈, 코드 재사용, extract
autovibe: true
version: "1.0"
created: "2026-02-22"
group: base
tier: null
inherits: null
argument-hint: "analyze|extract|check|plan|status [--scope {path}] [--service {name}]"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# av-base-refactor — 마이크로서비스 리팩토링 스킬

> {{PROJECT_NAME}} 모노레포에서 중복 코드를 탐지하고 공통 모듈 추출 계획을 자동 생성한다.

## Arguments

| 인자 | 필수 | 설명 | 기본값 |
|------|:----:|------|--------|
| `subcommand` | ✅ | analyze/extract/check/plan/status | — |
| `--scope` | ❌ | 분석 대상 경로 글로브 패턴 | `{{PROJECT_SRC}}/**` |
| `--service` | ❌ | 특정 서비스 이름 (acc, hcm, sys 등) | — |
| `--threshold` | ❌ | 중복 감지 최소 반복 횟수 | `3` |
| `--output` | ❌ | 추출 대상 패키지 경로 | `packages/common/src/` |

## Subcommands

### analyze

```
/av-base-refactor analyze [--scope {path}] [--service {name}]
```

모노레포 전체 또는 지정 범위에서 리팩토링 기회를 탐지한다.

**단계**:
1. Glob으로 대상 `.ts`, `.tsx`, `.prisma` 파일 수집
2. Grep으로 중복 패턴 탐지:
   - 동일/유사 함수 3회 이상 반복 (`findAll`, `findOne`, `create`, `update` 패턴)
   - `packages/common`에 없는 공통 유틸 (날짜, 포맷, 검증, 암호화)
   - 서비스별 중복 {{ORM_NAME}} 쿼리 패턴 ({{MULTI_TENANT_FIELD}} 필터, deletedAt 체크)
   - 서비스별 동일 {{BACKEND_FRAMEWORK}} 모듈 구조 반복 (PaginationQuery, SortOrder 등)
   - {{FRONTEND_FRAMEWORK}} 중복 훅 (`useQuery` 직접 사용 vs `useApiList`)
3. 탐지 결과를 우선순위별 분류:
   - HIGH: 5회 이상 반복 + 비즈니스 로직 포함
   - MEDIUM: 3~4회 반복 + 유틸성
   - LOW: 2회 반복 또는 단순 상수

**출력 형식**:
```markdown
## 리팩토링 분석 결과

### HIGH 우선순위 (N개)
- [R1] {패턴 설명} — 발견 위치: {파일1}, {파일2}, ...
  → 권장: {packages/common/src/...}로 추출

### MEDIUM 우선순위 (N개)
- [R2] ...

### 요약
| 우선순위 | 개수 | 절감 예상 줄수 |
|---------|------|-------------|
| HIGH    | N    | ~NNN 줄     |
| MEDIUM  | N    | ~NNN 줄     |
```

### extract

```
/av-base-refactor extract [target] [--output {package-path}]
```

`analyze`에서 감지된 패턴 또는 지정 타겟을 공통 모듈로 추출한다.

**단계**:
1. 추출 대상 코드 Read
2. 인터페이스/타입 의존성 분석 (다른 서비스 의존 여부 확인)
3. 출력 경로 결정 (기본: `packages/common/src/{category}/`)
4. AskUserQuestion → 추출 범위, 파일명, export 이름 확인
5. 공통 모듈 파일 생성 (타입 안전성 보장)
6. 기존 파일들에서 import 경로 수정 (`{{PACKAGE_SCOPE}}/common` 패키지)
7. `packages/common/src/index.ts` export 추가

**카테고리 분류**:
| 카테고리 | 경로 | 대상 |
|---------|------|------|
| dto | `packages/common/src/dto/` | 공통 DTO, 페이지네이션 |
| utils | `packages/common/src/utils/` | 날짜, 포맷, 검증 유틸 |
| types | `packages/common/src/types/` | 공통 타입, 인터페이스 |
| filters | `packages/common/src/filters/` | 예외 필터 |
| guards | `packages/common/src/guards/` | 공통 가드 |
| ui | `packages/ui/src/components/` | React 공통 컴포넌트 |

### check

```
/av-base-refactor check [file-or-dir]
```

특정 파일/디렉토리의 리팩토링 필요성을 즉시 진단한다.

**단계**:
1. Read 대상 파일
2. 다음 항목 체크:
   - 함수 크기 > 50줄 (분리 필요)
   - 3중 이상 중첩 조건문 (복잡도 과다, 추출 권장)
   - 하드코딩 상수 (enum/const 추출 필요)
   - 서비스 간 동일 로직 복사 (공통 모듈 후보)
   - `import type` 오용 ({{BACKEND_FRAMEWORK}} DI 크래시 위험)
   - 직접 {{ORM_NAME}} 쿼리 중 {{MULTI_TENANT_FIELD}} 필터 누락
3. 결과 출력:
   ```
   ✅ REFACTOR OK     — 리팩토링 불필요, 공통 모듈 잘 활용 중
   ⚠️ REFACTOR SUGGESTED — {N}개 항목 발견 (상세 목록 포함)
   ❌ REFACTOR REQUIRED  — 긴급 리팩토링 필요 (중복 임계값 초과)
   ```

### plan

```
/av-base-refactor plan [--scope {path}]
```

`analyze` 결과를 기반으로 단계별 리팩토링 실행 계획을 작성한다.

**단계**:
1. analyze 자동 실행 (캐시 있으면 재사용)
2. 의존성 그래프 기반 실행 순서 결정:
   - 1단계: `packages/common` 공통 타입/DTO 추출 (의존성 없음)
   - 2단계: 유틸 함수 추출 (타입 의존)
   - 3단계: 서비스 코드 import 경로 수정
3. PDCA Plan 형식으로 문서 생성:
   `docs/01-plan/features/refactoring-{YYYY-MM-DD}.plan.md`
4. 각 태스크에 예상 변경 파일 목록, 우선순위, 담당 스킬 포함

### status

```
/av-base-refactor status
```

현재 리팩토링 진행 상황 보고.

**단계**:
1. Glob으로 `docs/01-plan/features/refactoring-*.plan.md` 최신 파일 탐색
2. Grep으로 완료(`[x]`)/진행중(`[-]`)/미착수(`[ ]`) 항목 카운트
3. 테이블 형식 출력 + 다음 권장 작업 제안

## 프로세스

```
시작 프로토콜 (protocols.md §1)
  ↓
STEP 1: Read .claude/skills/av-base-refactor/MEMORY.md → 컨텍스트 로드
STEP 2: Read 글로벌 MEMORY.md 상단 50줄 → 프로젝트 컨텍스트
STEP 3: 서브커맨드 파싱 → 해당 분기 실행
STEP 4: analyze 결과 있으면 .claude/work/refactor-analysis-{date}.md에 캐시
  ↓
구조화 보고서 작성 (protocols.md §4)
  ↓
av-base-auditor 감사 요청 (audit-rules.md §2)
  ↓
PASS → 종료 | FAIL → 재작업 (최대 3회)

⚠️ av-base-refactor-advisor 에이전트 자동 트리거:
   extract 명령으로 코드 파일이 Write/Edit 되는 즉시
   av-base-write-monitor 훅 → av-base-refactor-advisor 에이전트가 자동 실행됨.
   추가 공통 모듈 추출 기회, 중복 패턴, 구조 개선 사항을 제안한다.
   스킬에서 명시적으로 Task 호출 불필요 (Hook 기반 자동 트리거).
```

## {{PROJECT_NAME}} 공통 모듈 추출 규칙

### packages/common 추가 대상
- 페이지네이션 쿼리 DTO (`PaginationQueryDto`, `SortOrder`)
- API 응답 래퍼 타입 (`ApiResponse<T>`, `PaginatedResponse<T>`)
- 공통 예외 필터 (RFC 7807 형식)
- 테넌트 컨텍스트 헬퍼 (`getTenantId()`)
- 날짜/시간 유틸 (day.js 래퍼)
- 암호화 유틸 (crypto 패키지 래퍼)

### packages/ui 추가 대상
- N개(기본: 3개) 이상 서비스에서 동일하게 사용하는 컴포넌트
- 공통 훅 (`useApiList`, `usePagination`, `useConfirm`)
- 공통 타입 (`MenuItemType`, `BreadcrumbItem`, `TableColumn`)

### 금지 사항
- 도메인 특화 비즈니스 로직을 공통 모듈로 추출 금지
- 단일 사용 코드를 공통 모듈화 금지 (YAGNI 원칙)
- 미완성 서비스의 코드를 early 추출 금지

## 실행 프로토콜 참조

- 시작/종료 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`

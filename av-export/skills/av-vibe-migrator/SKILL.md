---
name: av-vibe-migrator
description: |
  .claude/ 디렉토리 기존 구성요소를 AutoVibe 생태계로 마이그레이션.
  스캔 → 분류(삭제/통합/변환/등록) → 실행 3단계 워크플로우.
  트리거: migrate, 마이그레이션, autovibe 변환, .claude 정리, 통합
autovibe: true
version: "1.0"
created: "2026-02-22"
group: vibe
tier: meta
inherits: null
argument-hint: "scan | run [--dry-run] | delete <name> | consolidate <names> | status"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task]
---

# av-vibe-migrator — AutoVibe 마이그레이션 오케스트레이터

> `.claude/` 레거시 구성요소를 AutoVibe 생태계로 마이그레이션하는 마스터 스킬.
> scan → classify → execute 3단계로 안전하게 진행.

## Arguments

| 인자 | 필수 | 설명 | 기본값 |
|------|:----:|------|--------|
| `scan` | — | 전체 스캔 후 마이그레이션 계획 리포트 출력 | — |
| `run` | — | 실제 마이그레이션 실행 (scan 선행 필요) | — |
| `--dry-run` | ❌ | run 시 실행 없이 예상 결과만 출력 | false |
| `delete <name>` | — | 특정 구성요소 삭제 (확인 후) | — |
| `consolidate <a> <b>` | — | 두 구성요소 통합 (a → b로 병합) | — |
| `status` | — | 마이그레이션 현황 (미처리 항목 수) | — |

---

## 서브커맨드 상세

### scan — 현황 스캔 및 분류

```
/av-vibe-migrator scan
```

전체 `.claude/` 디렉토리를 스캔하여 각 구성요소를 5가지 액션으로 분류합니다.

**단계**:
```
STEP 1: Glob .claude/{hooks,skills,agents,rules}/** → 파일 목록 수집
STEP 2: Read .claude/registry/components.json → 등록 현황 로드
STEP 3: 각 파일에 대해 분류 알고리즘 실행 (아래 참조)
STEP 4: .claude/skills/av-vibe-migrator/work/migration-plan.md 생성
STEP 5: 요약 리포트 출력 (카테고리별 개수 + 상세 목록)
```

**분류 알고리즘**:

```
IF components.json에 등록됨 AND autovibe: true
  → SKIP (이미 AutoVibe 완료)

IF components.json에 등록됨 AND autovibe: false
  → REGISTER (레지스트리는 있으나 AutoVibe 메타데이터 미적용)

IF 미등록 AND 파일명에 av- 접두어 있음
  → REGISTER (레지스트리 누락, frontmatter 검증 필요)

IF 미등록 AND 파일명에 av- 없음 AND 기능 중복 탐지
  → CONSOLIDATE (기존 av- 컴포넌트와 통합 권장)

IF 미등록 AND 파일명에 av- 없음 AND 고유 기능
  → MIGRATE (av- 네이밍 + frontmatter 추가 후 등록)

IF 파일이 더 이상 필요 없거나 상위 컴포넌트에 흡수됨
  → DELETE (삭제 권장)
```

**리포트 형식**:

```
=== AutoVibe 마이그레이션 스캔 결과 ===

[SKIP]        N개 — 이미 AutoVibe 완료 (변경 불필요)
[REGISTER]    N개 — 레지스트리 등록만 필요
[MIGRATE]     N개 — av- 전환 필요 (frontmatter + 등록)
[CONSOLIDATE] N개 — 기존 컴포넌트와 통합 권장
[DELETE]      N개 — 삭제 권장

─────────────────────────────────────────────
SKIP: (av-base-content-scan, av-session-discovery, ...)
REGISTER: (mcp-memory-first.md, mermaid-standard.md, ...)
MIGRATE: (post-tool-format.sh, pre-write-template-check.sh, ...)
CONSOLIDATE: (session-start.sh → av-session-discovery, ...)
DELETE: (pre-write-template-check.sh 기능 av-base-content-scan 흡수 후 삭제, ...)
─────────────────────────────────────────────
→ /av-vibe-migrator run --dry-run  으로 예상 결과 확인
→ /av-vibe-migrator run            으로 실행
```

---

### run [--dry-run] — 마이그레이션 실행

```
/av-vibe-migrator run
/av-vibe-migrator run --dry-run
```

scan 결과(`migration-plan.md`)를 기반으로 실제 마이그레이션을 실행합니다.

**전제조건**: scan이 먼저 실행되어 `migration-plan.md`가 존재해야 함.

**단계**:
```
STEP 1: Read .claude/skills/av-vibe-migrator/work/migration-plan.md
STEP 2: AskUserQuestion → 각 액션 확인 (MIGRATE/DELETE/CONSOLIDATE 항목)
STEP 3: 승인된 항목 순서대로 실행:
        a. DELETE:      파일 삭제 + registry 항목 제거
        b. CONSOLIDATE: 기능 병합 + 구 파일 삭제 + registry 갱신
        c. MIGRATE:     frontmatter 추가 + 이름 변경 + registry 등록
        d. REGISTER:    registry 항목만 추가 (파일 수정 없음)
STEP 4: .claude/settings.json Hook 등록 갱신 (필요 시)
STEP 5: registry _meta.total 재계산 + 갱신
STEP 6: CLAUDE.md Skills/AutoVibe 섹션 업데이트
STEP 7: 완료 보고서 출력
```

**dry-run 모드**: 파일 변경 없이 STEP 3의 예상 결과를 텍스트로만 출력.

---

### delete \<name\> — 단일 삭제

```
/av-vibe-migrator delete session-start.sh
/av-vibe-migrator delete pre-write-template-check.sh
```

특정 구성요소를 안전하게 삭제합니다.

**단계**:
```
STEP 1: 파일 존재 확인
STEP 2: registry 등록 여부 확인
STEP 3: settings.json Hook 등록 여부 확인
STEP 4: AskUserQuestion → 삭제 확인 (파일 내용 미리보기 포함)
STEP 5: Bash rm → 파일 삭제
STEP 6: registry 항목 제거 (등록된 경우)
STEP 7: settings.json Hook 제거 (등록된 경우)
STEP 8: registry _meta.total 갱신
```

---

### consolidate \<source\> \<target\> — 통합

```
/av-vibe-migrator consolidate session-start.sh av-base-session-init
/av-vibe-migrator consolidate post-write-meta-verify.sh av-base-content-scan
```

source의 고유 기능을 target에 병합 후 source를 삭제합니다.

**단계**:
```
STEP 1: Read source 파일 + Read target 파일
STEP 2: 기능 비교 분석 (중복 제거, 고유 기능 식별)
STEP 3: AskUserQuestion → 병합 방식 확인 (통합할 기능 목록 표시)
STEP 4: Edit target → 고유 기능 통합
STEP 5: target version Minor+1 갱신
STEP 6: registry target version 갱신
STEP 7: source 파일 삭제 + registry 제거 (source가 등록된 경우)
STEP 8: settings.json 갱신 (source Hook 제거)
```

---

### status — 현황 확인

```
/av-vibe-migrator status
```

```
=== 마이그레이션 현황 ===
스캔 일시: YYYY-MM-DD HH:MM (없으면 "스캔 미실행")
미처리 항목: N개 (MIGRATE: N, DELETE: N, CONSOLIDATE: N, REGISTER: N)
완료 항목: N개
→ /av-vibe-migrator scan  으로 최신 상태 확인
```

---

## {{PROJECT_NAME}} 프로젝트 마이그레이션 컨텍스트

### 현재 분석 결과 (2026-02-22 기준)

스캔 없이 사전 파악한 이 프로젝트의 마이그레이션 대상:

#### SKIP (처리 불필요 — 이미 AutoVibe)

| 파일 | 유형 | 이유 |
|------|------|------|
| `av-content-scanner.sh` | Hook | autovibe:true, registered v1.1 |
| `av-session-discovery.sh` | Hook | autovibe:true, registered v1.0 |
| `av-post-write-monitor.sh` | Hook | autovibe:true, registered v1.0 |
| `av-bash-guard.sh` | Hook | autovibe:true, registered v1.0 |
| `av-base-auditor.md` | Agent | autovibe:true, registered v1.0 |
| `av-vibe-vibecoder.md` | Agent | autovibe:true, registered v1.0 |
| `av-acc-auditor.md` | Agent | autovibe:true, registered v1.0 |
| `av-vibe-forge/` | Skill | autovibe:true, registered v1.1 |
| `av-vibe-skill-forge/` | Skill | autovibe:true, registered v1.0 |
| `av-vibe-agent-forge/` | Skill | autovibe:true, registered v1.0 |
| `av-vibe-hook-forge/` | Skill | autovibe:true, registered v1.0 |
| `av-vibe-rule-forge/` | Skill | autovibe:true, registered v1.0 |
| `av-claude-code-spec.md` | Rule | autovibe:true, registered v1.0 |

#### DELETE (삭제 권장)

| 파일 | 이유 | 대체 |
|------|------|------|
| `hooks/session-start.sh` | av-session-discovery.sh가 기능 전체 흡수 (+ AutoVibe 상태 주입 추가) | av-base-session-init |
| `hooks/pre-write-template-check.sh` | @template 강제는 현재 워크플로우에서 미사용. av-content-scanner가 더 포괄적 처리 | av-base-content-scan |
| `hooks/post-write-meta-verify.sh` | @template/@service/@module 태그 규칙 폐기됨 ({{PROJECT_NAME}} 표준에서 제거) | 삭제 후 재도입 불필요 |
| `hooks/post-tool-format.sh` | Claude Code Hook stdout 방식과 불일치 (파일 경로를 $1로 받는 구형 방식). {{LINTER_NAME}}이 lint 포맷 담당 | av-base-content-scan 또는 별도 신규 |

#### CONSOLIDATE (기능 통합)

| source | target | 통합할 기능 |
|--------|--------|------------|
| `hooks/pre-commit-docs-sync.sh` | `skills/docs-sync` 스킬 내 Hook 정의로 이관 | git commit 전 동기화 경고 |

#### MIGRATE (av- 전환)

| 파일 | 제안 이름 | 그룹 | 처리 방법 |
|------|-----------|------|----------|
| `hooks/pre-commit-docs-sync.sh` | `av-base-precommit-sync` | base | frontmatter(주석) + registry 등록 |

#### REGISTER (레지스트리 등록만)

| 파일 | 유형 | autovibe | 처리 방법 |
|------|------|:--------:|----------|
| `rules/av-base-memory-first.md` | Rule | true | registry 등록 (group=base, autovibe=false) |
| `rules/av-util-mermaid-standard.md` | Rule | true | registry 등록 (group=base, autovibe=false) |
| `skills/saas-code-gen/` | Skill | false | 이미 등록됨 (SKIP) |
| `skills/mermaid/` | Skill | false | registry 등록 (group=base, autovibe=false) |
| `skills/prisma-manage/` | Skill | false | 이미 등록됨 (SKIP) |
| `skills/db-query/` | Skill | false | 이미 등록됨 (SKIP) |

#### REVIEW (수동 검토 필요)

미등록 비av- 스킬 목록 (기능 중복 또는 활용도 저하 여부 검토):

| 스킬 | 활용 여부 | 권장 |
|------|----------|------|
| `manage-skills/` | av-vibe-forge로 대체됨 | DELETE 검토 |
| `skill-builder/` | av-vibe-forge로 대체됨 | DELETE 검토 |
| `legacy-analyze/` + `legacy-analyzer/` | 이름 중복, 기능 유사 | CONSOLIDATE 검토 |
| `dev-guide-gen/`, `e2e-doc-gen/`, `tech-learning-guide-gen/` | 활용 중 | registry REGISTER |
| `saas-doc-gen/`, `saas-review/`, `saas-test/` | 활용 중 | registry REGISTER |
| `erp-quality/`, `infra-build/`, `service-integrator/` | 활용 중 | registry REGISTER |
| `shadcn-ref/`, `redis-ops/`, `mermaid/` | 활용 중 (MCP 대체) | registry REGISTER |
| `template-manager/` | template-agent와 중복 가능 | CONSOLIDATE 검토 |
| `ui-ux-expert/` + `ui-ux-dev/` | ui-ux-dev 등록됨 | ui-ux-expert REGISTER |

---

## 프로세스

```
시작 프로토콜 (protocols.md §1)
  ↓
scan: Glob + Read + 분류 알고리즘
  ↓
AskUserQuestion: 각 마이그레이션 액션 확인
  ↓
run: DELETE → CONSOLIDATE → MIGRATE → REGISTER 순서
  ↓
settings.json + registry + CLAUDE.md 갱신
  ↓
구조화 보고서 작성 (protocols.md §4)
  ↓
av-base-auditor 감사 요청 Level 3 (registry 수정)
  ↓
PASS → 종료 | FAIL → 재작업 (최대 3회)
```

## 실행 프로토콜 참조

- 시작/종료 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`
- 네이밍 규칙: `.claude/docs/av-claude-code-spec/topics/naming-rules.md`
- Frontmatter 명세: `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md`

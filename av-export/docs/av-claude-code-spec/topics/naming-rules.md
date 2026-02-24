# Naming Rules — av- 네이밍 + 도메인 + OOP 상속

> Plan §10, §12 참조.

## 1. av- 접두사 시스템 (Plan §12)

```
av- = AutoVibe Generated
완전한 형식: av-{domain}-{name}

분해:
  av-           = AutoVibe 식별자 (필수, 항상 첫 번째)
  {domain}-     = 도메인 접두사 (필수, 정의된 도메인 목록에서 선택)
  {name}        = 컴포넌트 기능명 (kebab-case)
```

| 범위 | Agent | Skill (디렉토리) | Hook | Rule |
|------|-------|-----------------|------|------|
| base | `av-base-auditor.md` | `av-base-code-quality/` | `av-base-bash-guard.sh` | `av-base-spec.md` |
| vibe | `av-vibe-vibecoder.md` | `av-vibe-forge/` | — | — |
| util | — | `av-util-redis/` | — | `av-util-mermaid-std.md` |
| erp | `av-erp-migrator.md` | `av-erp-migration/` | — | — |

## 2. 도메인 체계 (Domain Taxonomy)

### 생태계 도메인 (이식 가능 — portable)

| 도메인 | 설명 | 이식 | 용도 |
|--------|------|:----:|------|
| `vibe` | 생태계 메타 도구 | 항상 | forge, migrator, portable-init — 생태계 자체 생성/관리/이식 |
| `base` | 핵심 필수 도구 | 항상 | 감사, 품질, git, 동기화, 리팩토링, QA — 기술스택 무관 |
| `util` | 확장 선택 도구 | 선택 | Redis, Shadcn, Mermaid, 가이드 생성 — 기술스택 의존 |

### 프로젝트 도메인 (이식 제외 — project-specific)

> 아래 도메인은 템플릿 예시. `/av-vibe-portable-init customize`로 언제든 재정의 가능.

| 도메인 | 설명 | 이식 | 용도 |
|--------|------|:----:|------|
| `erp` | ERP 전용 | 제외 | {{PROJECT_NAME}} ERP 전용 구현/검증/마이그레이션 |
| `do` | 파이프라인 | 제외 | PDCA Do-phase 실행 에이전트 |
| `legacy` | 레거시 | 제외 | Java ERP 분석/변환 도구 |
| `acc` / `bdg` / 기타 | 서비스 | 제외 | 특정 서비스 전용 컴포넌트 |

### base vs util 분류 기준

```
base: "기술 스택에 무관하게 모든 프로젝트에서 필요한 도구인가?"
  → YES = base (감사, 품질, git, 동기화, 리팩토링)

util: "특정 기술/프레임워크에 의존하거나, 없어도 프로젝트 진행이 되는가?"
  → YES = util (Redis, Shadcn, Mermaid, 가이드 생성)
```

## 3. 이식 판별 알고리즘 (이름 기반)

```
av-vibe-*       → 생태계 핵심 → 항상 이식
av-base-*       → 범용 필수   → 항상 이식
av-util-*       → 범용 선택   → 기술스택 맞으면 이식
av-{project}-*  → 프로젝트 전용 → 이식 제외
```

### 이식 기준 (레지스트리 필드)

```
이식 O: domain in ["vibe", "base", "util"] AND autovibe === true
이식 X: domain in ["erp", "do", "legacy", "acc", ...] (프로젝트 도메인)
이식 X: autovibe === false (수동 생성 유틸리티)
```

## 4. 6대 네이밍 규칙

```
규칙 1: 도메인 접두사는 정의된 도메인 목록에서 선택
  ✅ av-base-auditor   ❌ av-common-auditor  ❌ av-shared-auditor

규칙 2: 모든 컴포넌트는 도메인 접두사 필수
  ✅ av-base-auditor, av-erp-build-stabilizer  ❌ av-auditor (접두사 없음)

규칙 3: vibe 그룹은 항상 vibe- 접두사
  ✅ av-vibe-forge, av-vibe-portable-init  ❌ av-portable-init

### 예외: 마스터 게이트웨이

`av` 스킬은 전체 생태계의 최상위 진입점으로, 규칙 3(vibe- 접두사)의 예외.
이유: av = AutoVibe 약어이므로 av-vibe-av 중복 방지.
위치: `.claude/skills/av/SKILL.md` | domain: vibe | tier: meta

규칙 4: 상속 시 scope 축소 (Liskov 원칙)
  ✅ av-base-auditor scope=".claude/**" → av-acc-auditor scope="services/core/acc/**"
  ❌ av-acc-auditor scope=".claude/**"  (부모보다 넓은 scope 금지)

규칙 5: kebab-case, 최대 4단어 (도메인 포함)
  ✅ av-base-auditor (3)  ✅ av-base-code-quality (4)  ✅ av-erp-verify-nestjs (4)
  ❌ av-acc_code_gen (언더스코어 금지)
  ❌ av-base-claude-sync-auditor (5단어 초과 → 축약: av-base-sync-auditor)

규칙 6: 레지스트리 등록 없이 생성 금지
  → /av-vibe-forge 통해서만 생성 (components.json 자동 업데이트)
```

## 5. Skill-Agent 쌍 네이밍 규칙

```
Skill: av-{domain}-{verb/noun} (행위 중심)
Agent: av-{domain}-{noun/er}   (역할 중심)

예시:
  av-base-git-commit (skill)  ↔ av-base-git-committer (agent)
  av-base-sync (skill)        ↔ av-base-sync-auditor (agent)
  av-base-refactor (skill)    ↔ av-base-refactor-advisor (agent)
  av-base-post-qa (skill)     ↔ av-base-qa-reviewer (agent)
```

## 6. OOP 상속 시스템 (Plan §10.3)

### 상속 계층 (최대 3단계)

```
Level 0: base (공통 기반)
Level 1: domain (도메인 계층, 선택)
Level 2: service (서비스 특화)

예시:
  av-base-auditor                ← Level 0 (base)
      ├── av-erp-auditor         ← Level 1 (erp domain, 선택)
      │    └── av-acc-auditor    ← Level 2 (acc service)
      └── av-erp-fe-auditor      ← Level 2 (fe 특화)
```

### 상속 body 4섹션 규칙

자식 컴포넌트는 body에 다음 4섹션을 반드시 포함:

```markdown
## 상속 컨텍스트
> 이 컴포넌트는 `av-{parent}`를 상속합니다.
> 작업 시작 전 부모 파일을 Read하여 공통 로직을 확인하세요.

## 오버라이드 항목
| 항목 | 부모 값 | 이 컴포넌트 값 |

## 공통 로직 (부모에서 상속)
[부모의 모든 로직 그대로 실행]

## {domain} 전용 추가 로직
[도메인/서비스 특화 추가 검증]
```

## 7. av- 적용 대상 vs 미적용

| 유형 | av- 적용 | 이유 |
|------|:--------:|------|
| Rule (.md) | ✅ | 생태계 생성 규칙 |
| Agent (.md) | ✅ | 생태계 생성 에이전트 |
| Skill (디렉토리) | ✅ | 생태계 생성 스킬 |
| Hook (.sh) | ✅ | 생태계 생성 훅 |
| Template (.tmpl) | ❌ | 메타도구 (컴포넌트 생성 도구) |
| Registry (json) | ❌ | 메타 관리 파일 |
| CLAUDE.md | ❌ | 프로젝트 루트 설정 |

## 8. 공존 규칙 (수동 vs av-)

```
av- → 수동 부모 상속 허용 (단방향)
  ✅ av-erp-codegen inherits saas-code-gen
  ✅ av-acc-auditor inherits av-base-auditor
  ❌ saas-code-gen  inherits av-*  (수동 → av- 금지)

수동 컴포넌트 (접두사 없음):
  - AutoVibe가 읽기만 하고 수정 안 함
  - 레지스트리에 domain=null, autovibe=false로 등록
```

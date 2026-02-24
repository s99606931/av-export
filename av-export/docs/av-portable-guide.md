# av-portable-guide — AutoVibe 이식 가이드

> AutoVibe(av-) 프레임워크를 {{PROJECT_NAME}} ERP에서 다른 프로젝트로 이식하는 완전 가이드.
> 4-tier 도메인 체계(vibe/base/util) 36개 컴포넌트를 원클릭으로 이식.
> **현재 최신**: v4.0 (2026-02-24 — Sanitize/Hydrate 자동화 시스템 추가)

---

## 0. Sanitize/Hydrate 시스템 개요

> v4.0부터 export 시 자동 정화(Sanitize), 이식 시 자동 복원(Hydrate) 기능이 추가되었습니다.

### 전체 플로우

```
[{{PROJECT_NAME}}]                           [새 프로젝트]
  │                                      │
  ▼                                      ▼
export --portable                   install.sh
  │                                      │
  ▼                                      ▼
① 파일 수집                         /av-vibe-portable-init setup
  │                                      │
  ▼                                      ▼
② Sanitize 자동 실행              ② 프로젝트 정보 수집 (Q1~Q6)
  {{PROJECT_NAME}} → {{PLACEHOLDER}}             │
  MEMORY.md 초기화                       ▼
  ERP 예시 → 범용 예시            ② Hydrate 자동 실행
  │                               {{PLACEHOLDER}} → 실제값
  ▼                               스택 프리셋 적용
sanitize-report.json              hydrate-report.json
  │                                      │
  ▼                                      ▼
av-export/ (정화된 패키지)         .claude/ (프로젝트 맞춤화 완료)
```

### 왜 Sanitize/Hydrate인가?

| 문제 | 해결 |
|------|------|
| {{PROJECT_NAME}} 경로(`{{PROJECT_ROOT}}`)가 다른 프로젝트에서 오류 발생 | `{{PROJECT_ROOT}}`로 치환 후 실제 경로 복원 |
| `{{PACKAGE_SCOPE}}` 패키지 스코프가 이식 프로젝트에서 미작동 | `{{PACKAGE_SCOPE}}`로 치환 후 복원 |
| {{PROJECT_NAME}} 이력 데이터가 MEMORY.md에 노출됨 | 빈 템플릿으로 완전 초기화 |
| ERP 모듈 예시(`acc/bdg/pay`)가 혼란 유발 | 범용 `{service}/{module}` 예시로 교체 |

---

## 0.5. 플레이스홀더 전체 목록 (14개)

**Tier 1 — 필수 (setup 시 반드시 입력)**

| 플레이스홀더 | {{PROJECT_NAME}} 실제값 | 기본값 | 설명 |
|---|---|---|---|
| `{{PROJECT_NAME}}` | {{PROJECT_NAME}} | MyProject | 프로젝트 이름 |
| `{{PROJECT_ROOT}}` | {{PROJECT_ROOT}} | (자동감지: pwd) | 프로젝트 절대 루트 경로 |
| `{{PROJECT_SRC}}` | {{PROJECT_SRC}} | src | 소스 루트 상대 경로 |
| `{{PACKAGE_SCOPE}}` | {{PACKAGE_SCOPE}} | @myproject | npm 패키지 스코프 |
| `{{BACKEND_FRAMEWORK}}` | {{BACKEND_FRAMEWORK}} | (선택) | 백엔드 프레임워크명 |
| `{{FRONTEND_FRAMEWORK}}` | {{FRONTEND_FRAMEWORK}} | (선택) | 프론트엔드 프레임워크명 |

**Tier 2 — 조건부 (스택에 따라 자동 설정 또는 선택)**

| 플레이스홀더 | {{PROJECT_NAME}} 실제값 | 기본값 | 설명 |
|---|---|---|---|
| `{{ORM_NAME}}` | {{ORM_NAME}} | none | ORM/데이터베이스 추상화 계층 |
| `{{MESSAGING_SYSTEM}}` | {{MESSAGING_SYSTEM}} | none | 메시징 시스템 |
| `{{MONOREPO_TOOL}}` | {{MONOREPO_TOOL}} | none | 모노레포 관리 도구 |
| `{{LINTER_NAME}}` | {{LINTER_NAME}} | ESLint | 린터/포매터 |
| `{{PKG_MANAGER}}` | {{PKG_MANAGER}} | npm | 패키지 매니저 |
| `{{BUILD_COMMAND}}` | {{BUILD_COMMAND}} | npm run build | 빌드 실행 명령어 |
| `{{MULTI_TENANT_FIELD}}` | {{MULTI_TENANT_FIELD}} | none | 멀티테넌트 식별 필드 |
| `{{PROJECT_DOMAIN}}` | {{PROJECT_DOMAIN}} | (입력) | 프로젝트 도메인 설명 |

---

## 0.6. 기술 스택 프리셋 (5종)

`/av-vibe-portable-init setup` 시 선택한 스택에 따라 자동 적용됩니다.

| 프리셋 | 적용 스택 | 감사 규칙(체크 3) | 빌드 명령 |
|--------|---------|-----------------|---------|
| `{{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}}` | {{BACKEND_FRAMEWORK}}+{{FRONTEND_FRAMEWORK}} 풀스택 | {{BACKEND_FRAMEWORK}} DI, {{ORM_NAME}} 7 규칙 | {{PKG_MANAGER}} turbo build |
| `FastAPI+React` | FastAPI+React 풀스택 | FastAPI Router/DI, SQLAlchemy | pytest + npm build |
| `Django+React` | Django+React 풀스택 | Django View/Serializer, ORM | python manage.py + npm |
| `Go+React` | Go+React 풀스택 | Handler/Service/Repository | go build + npm build |
| `generic` | 기타 모든 스택 | 기본 컨벤션 (직접 편집 필요) | npm run build |

---

## 0. 도메인 체계 요약

```
이식 판별 알고리즘 (이름만 보고 즉시 판단):

  av-vibe-* → 생태계 핵심 도구 → 항상 이식
  av-base-* → 범용 필수 도구  → 항상 이식
  av-util-* → 범용 선택 도구  → 기술스택 맞으면 이식
  av-erp-*  → ERP 프로젝트 전용 → 이식 제외
  av-do-*   → PDCA 파이프라인  → 이식 제외
  av-legacy-* → 레거시 전용   → 이식 제외
```

---

## 1. 사전 요구사항

```
필수:
- Claude Code CLI 설치  → claude --version (v1.0 이상)
- git 초기화된 프로젝트 → git init (없으면 먼저 실행)

선택:
- jq 설치              → jq --version (JSON 처리 자동화)
- rsync 설치           → rsync --version (원격 전송 시)
```

---

## 2. 빠른 시작 (3단계)

### ① {{PROJECT_NAME}}에서 portable 패키지 내보내기 (자동 정화 포함)

```bash
# {{PROJECT_NAME}} 프로젝트에서 실행
/av-vibe-forge export --portable
```

> v4.0부터 export 완료 후 **자동으로 Sanitize(정화)가 실행됩니다**.
> {{PROJECT_NAME}} 고유정보가 플레이스홀더로 치환되어 다른 프로젝트에 바로 이식 가능합니다.
> 정화 결과는 `av-export/sanitize-report.json`에서 확인.

생성 경로: `av-export/`

포함 컴포넌트 (36개 + 부가파일):
- **Rule 3개** (av-base-spec, av-base-memory-first, av-util-mermaid-std)
- **Skill 19개** (av, av-vibe-* 7개, av-base-* 5개, av-util-* 6개)
- **Agent 9개** (av-base-* 8개, av-vibe-vibecoder)
- **Hook 5개** (av-base-bash-guard, av-base-content-scan, av-base-session-init, av-base-write-monitor, av-base-precommit-sync)
- **Docs 4개** (av-claude-code-spec/topics/*.md)
- **Template 16개** (docs/*.tmpl — av-memory-init-*.md.tmpl 신규 포함)
- **sanitize-rules.json** (정화/복원 규칙)
- **sanitize-report.json** (정화 결과 보고서)

### ② 대상 프로젝트로 패키지 복사

```bash
# 방법 A: rsync (로컬 프로젝트 간, 권장)
rsync -av {{PROJECT_ROOT}}/av-export/ /path/to/new-project/av-export/

# 방법 B: cp (단순 복사)
cp -r {{PROJECT_ROOT}}/av-export/ /path/to/new-project/.claude/

# 방법 C: scp (원격 서버)
scp -r {{PROJECT_ROOT}}/av-export/ user@host:/path/to/project/.claude/
```

### ③ 대상 프로젝트에서 초기화 실행 (자동 복원 포함)

```bash
# 대상 프로젝트의 Claude Code에서 실행
/av-vibe-portable-init setup
```

> v4.0부터 `setup` 시 **Q4~Q6 추가 질문** 후 자동으로 **Hydrate(복원)가 실행됩니다**.
> 입력한 프로젝트 정보로 플레이스홀더가 실제 값으로 복원됩니다.
> 복원 결과는 `.claude/hydrate-report.json`에서 확인.

setup 중 추가 질문 (v4.0 신규):

| 질문 | 예시 답변 | 플레이스홀더 |
|------|----------|------------|
| 소스 루트 경로? | `src` 또는 `packages/backend/src` | `{{PROJECT_SRC}}` |
| npm 패키지 스코프? | `@myapp` (없으면 Enter) | `{{PACKAGE_SCOPE}}` |
| 멀티테넌트 필드? | `{{MULTI_TENANT_FIELD}}` (없으면 Enter) | `{{MULTI_TENANT_FIELD}}` |

---

## 3. 이식 후 설정 가이드

> 이 섹션은 각 프로젝트별로 맞춤화하세요.
> `/av-vibe-portable-init setup` 실행 후 프로젝트에 맞게 내용이 자동 생성됩니다.

---

## 4. 커스터마이징 가이드

### 4.1 도메인/그룹 체계 정의

`setup` 실행 중 Q3에서 입력하거나, 이후에 직접 편집:

```markdown
# naming-rules.md의 ## 그룹 체계 섹션 편집 예시

[intent]   intent 파이프라인 도구 ({target-project} 전용)
[platform] 플랫폼 계층 서비스 (auth, api-gateway)
[core]     핵심 업무 서비스 (user, order, payment)
[ai]       AI 서비스 (recommendation, nlp)
```

또는 `/av-vibe-portable-init customize` → "그룹 체계 재정의" 선택

### 4.2 도메인 에이전트 생성

```bash
# 서비스별 전용 감사 에이전트
/av-vibe-forge agent {service}-auditor --group {group} --inherits av-base-auditor \
  --scope "src/services/{service}/**"
```

### 4.3 ROUTING_TABLE 확장

```bash
/av-vibe-portable-init customize
# → "ROUTING_TABLE 항목 추가" 선택

# 또는 .claude/skills/av/SKILL.md 직접 편집:
# creation + any → Skill("my-codegen", "run {layer}")
```

### 4.4 기술 스택별 감사 규칙

`av-base-auditor.md`의 **체크 3** 섹션을 스택에 맞게 수정:

| 스택 | 체크 3 내용 |
|------|-----------|
| {{BACKEND_FRAMEWORK}} + {{FRONTEND_FRAMEWORK}} | {{BACKEND_FRAMEWORK}} DI 패턴, {{ORM_NAME}} 7 규칙 |
| FastAPI + React | FastAPI Router/Dependency, SQLAlchemy |
| Django + React | Django View/Serializer, ORM 규칙 |
| Go + React | Handler/Service/Repository 패턴 |
| Python 파이프라인 | 모듈 임포트, 타입 힌트, flake8 기준 |

---

## 5. 이식 후 첫 작업 추천

```bash
# 1. 생태계 건강도 확인
/av-vibe-forge health

# 2. 첫 도메인 에이전트 생성
/av-vibe-forge agent {service}-auditor --group {group} --inherits av-base-auditor

# 3. 첫 커스텀 훅 생성 (필요 시)
/av-vibe-forge hook PreToolUse {name}-guard --group {group}

# 4. 코드 품질 게이트 초기 실행
/av-base-code-quality check

# 5. CLAUDE.md 최신화
/av-base-sync update
```

---

## 6. 이식 대상 컴포넌트 전체 목록

### 이식 O — vibe (생태계 핵심, 항상 이식)

| 유형 | 컴포넌트 | 설명 |
|------|---------|------|
| Skill | `av` | 마스터 게이트웨이 |
| Skill | `av-vibe-forge` | 마스터 오케스트레이터 |
| Skill | `av-vibe-skill-forge` | 스킬 생성기 |
| Skill | `av-vibe-agent-forge` | 에이전트 생성기 |
| Skill | `av-vibe-hook-forge` | 훅 생성기 |
| Skill | `av-vibe-rule-forge` | 룰 생성기 |
| Skill | `av-vibe-migrator` | 레거시 구성요소 마이그레이션 |
| Skill | `av-vibe-portable-init` | 이식 초기화 (이 스킬) |
| Agent | `av-vibe-vibecoder` | 갭 분석 + 컴포넌트 추천 |

### 이식 O — base (범용 필수, 항상 이식)

| 유형 | 컴포넌트 | 설명 |
|------|---------|------|
| Rule | `av-base-spec` | AutoVibe 중앙 규칙 인덱스 |
| Rule | `av-base-memory-first` | 에이전트 메모리 전략 |
| Skill | `av-base-code-quality` | 코드 품질 게이트 |
| Skill | `av-base-git-commit` | git 커밋 자동화 |
| Skill | `av-base-sync` | CLAUDE.md 자동 최신화 |
| Skill | `av-base-refactor` | 리팩토링 오케스트레이터 |
| Skill | `av-base-post-qa` | 대량 작업 후 QA 검수 |
| Agent | `av-base-auditor` | 감사 에이전트 (L1~L3) |
| Agent | `av-base-optimizer` | 최적화 분석 |
| Agent | `av-base-quality-auditor` | 코드 품질 자동 검사 |
| Agent | `av-base-git-committer` | git 커밋 메시지 생성 |
| Agent | `av-base-sync-auditor` | CLAUDE.md 정합성 감사 |
| Agent | `av-base-refactor-advisor` | 리팩토링 자동 제안 |
| Agent | `av-base-qa-reviewer` | QA 검수 에이전트 |
| Agent | `av-base-template` | 템플릿 관리 에이전트 |
| Hook | `av-base-bash-guard` | Bash 명령 안전 가드 |
| Hook | `av-base-content-scan` | 파일 내용 사전 검사 |
| Hook | `av-base-session-init` | 세션 시작 컨텍스트 로드 |
| Hook | `av-base-write-monitor` | 파일 작성 후 모니터링 |
| Hook | `av-base-precommit-sync` | 커밋 전 문서 동기화 |

### 이식 선택 — util (기술스택 의존)

| 유형 | 컴포넌트 | 설명 | 필요 환경 |
|------|---------|------|---------|
| Rule | `av-util-mermaid-std` | Mermaid 표준 규칙 | Mermaid 사용 시 |
| Skill | `av-util-redis` | Redis 조회/관리 | Redis 서버 |
| Skill | `av-util-shadcn` | shadcn/ui 레퍼런스 | {{FRONTEND_FRAMEWORK}} 프로젝트 |
| Skill | `av-util-mermaid` | Mermaid 다이어그램 | 다이어그램 문서화 |
| Skill | `av-util-dev-guide` | 개발자 가이드 생성 | 팀 온보딩 |
| Skill | `av-util-e2e-doc` | E2E 테스트 문서 | QA 팀 |
| Skill | `av-util-tech-guide` | 기술 학습 가이드 | 신규 개발자 |

### 이식 X — 프로젝트 전용 컴포넌트

```
제외 이유 A: {{PROJECT_NAME}} ERP 도메인 종속 (av-erp-*)
  av-erp-migration, av-erp-codegen, av-erp-uiux-dev, av-erp-fe-audit
  av-erp-verify-nestjs, av-erp-verify-prisma, av-erp-verify-exports
  av-erp-backend-guard, av-erp-frontend-guard, av-erp-infra-guard
  av-erp-migration-qa, av-erp-uiux-guard, av-erp-prisma, av-erp-db-query
  av-erp-integrator, av-erp-infra, av-erp-build-stabilizer, av-erp-docker
  av-erp-env-validator, av-erp-integration-tester

제외 이유 B: PDCA 파이프라인 전용 (av-do-*)
  av-do-orchestrator, av-do-db-agent, av-do-backend-agent
  av-do-api-spec-agent, av-do-e2e-agent

제외 이유 C: 레거시/회계 전용
  av-legacy-blueprint, av-legacy-analyzer, av-legacy-func-analyzer
  av-oracle-schema-mapper, av-uiux-blueprint-generator
  av-acc-auditor, av-erp-codegen, av-erp-docgen, av-erp-review, av-erp-test
```

---

## 7. GitHub 저장소 기반 배포 워크플로우

> **목표**: av- 생태계를 GitHub 저장소에 보관하고, 어느 프로젝트에서도 `git clone` 한 줄로 부트스트랩.

### 7.1 GitHub 저장소 구조

```
myorg/autovibe-ecosystem/          # 별도 GitHub 저장소
├── README.md                      # 설치 안내
├── install.sh                     # 자동 설치 스크립트
├── export-manifest.json           # 패키지 메타정보
├── portable-components.json       # 컴포넌트 레지스트리
├── skills/                        # 19개 av- 스킬
│   ├── av/
│   ├── av-vibe-forge/
│   └── ...
├── agents/                        # 9개 av- 에이전트
│   ├── av-base-auditor.md
│   ├── memory/                    # 에이전트 메모리 초기값
│   └── ...
├── hooks/                         # 5개 av- 훅
├── rules/                         # 3개 av- 룰
├── docs/                          # 문서
│   ├── av-ecosystem/              # 생태계 개발자 문서
│   ├── av-claude-code-spec/topics/
│   └── av-portable-guide.md
└── templates/                     # 14개 tmpl 파일
```

### 7.2 {{PROJECT_NAME}} → GitHub 업로드

```bash
# 1. av-export 패키지 최신화 ({{PROJECT_NAME}}에서)
/av-vibe-forge export --portable

# 2. GitHub 저장소 클론 (최초 1회)
git clone https://github.com/myorg/autovibe-ecosystem /tmp/autovibe-ecosystem

# 3. av-export 내용을 저장소로 복사
SRC="{{PROJECT_ROOT}}/av-export"
DST="/tmp/autovibe-ecosystem"

rsync -av --delete "$SRC/" "$DST/" \
  --exclude='.git' \
  --exclude='*.jsonl'

# 4. install.sh 추가 (최초 1회)
# → 7.3 참조

# 5. 커밋 & 푸시
cd /tmp/autovibe-ecosystem
git add -A
git commit -m "chore: av-ecosystem update $(date +%Y-%m-%d)

- Components: agents:9, skills:19, hooks:5, rules:3 (total:36)
- Domain: vibe/base/util portable components
- Guide: av-portable-guide.md v3.4"
git push origin main
```

### 7.3 install.sh — 자동 설치 스크립트

저장소에 `install.sh`를 추가하면 한 줄로 새 프로젝트에 설치 가능:

```bash
#!/bin/bash
# AutoVibe Ecosystem Installer
# 사용법: curl -fsSL https://raw.githubusercontent.com/myorg/autovibe-ecosystem/main/install.sh | bash
# 또는: bash install.sh [--target /path/to/project]

set -e

REPO_URL="https://github.com/myorg/autovibe-ecosystem"
REPO_BRANCH="main"
TARGET="${1:-$(pwd)}"
CLAUDE_DIR="$TARGET/.claude"

echo "=== AutoVibe Ecosystem Installer ==="
echo "대상: $CLAUDE_DIR"

# 1. 임시 클론
TMP=$(mktemp -d)
git clone --depth=1 --branch="$REPO_BRANCH" "$REPO_URL" "$TMP/av"

# 2. 디렉토리 생성
mkdir -p "$CLAUDE_DIR"/{skills,agents,agent-memory,hooks,rules,docs,templates/docs,registry}
mkdir -p "$CLAUDE_DIR/docs/av-claude-code-spec/topics"
mkdir -p "$CLAUDE_DIR/docs/av-ecosystem"

# 3. 파일 설치
cp -r "$TMP/av/skills/." "$CLAUDE_DIR/skills/"
cp -r "$TMP/av/agents/." "$CLAUDE_DIR/agents/" 2>/dev/null || true
rm -rf "$CLAUDE_DIR/agents/memory"
cp -r "$TMP/av/agents/memory/." "$CLAUDE_DIR/agent-memory/" 2>/dev/null || true
cp -r "$TMP/av/hooks/." "$CLAUDE_DIR/hooks/" && chmod +x "$CLAUDE_DIR/hooks/"*.sh
cp -r "$TMP/av/rules/." "$CLAUDE_DIR/rules/"
cp -r "$TMP/av/docs/." "$CLAUDE_DIR/docs/"
cp "$TMP/av/templates/"*.tmpl "$CLAUDE_DIR/templates/av-docs/"
cp "$TMP/av/portable-components.json" "$CLAUDE_DIR/registry/components.json"

# 4. 정리
rm -rf "$TMP"

echo ""
echo "✅ AutoVibe 생태계 설치 완료!"
echo "   Claude Code 재시작 후 /av-vibe-forge health 로 확인하세요."
```

### 7.4 새 프로젝트에서 GitHub 기반 부트스트랩

```bash
# 방법 A: install.sh 원라인 (저장소에 install.sh가 있을 때)
curl -fsSL https://raw.githubusercontent.com/myorg/autovibe-ecosystem/main/install.sh \
  | bash -s -- --target /path/to/new-project

# 방법 B: git clone 후 수동 실행
git clone --depth=1 https://github.com/myorg/autovibe-ecosystem /tmp/av-eco
bash /tmp/av-eco/install.sh --target /path/to/new-project

# 방법 C: 로컬에 이미 클론된 저장소 사용
bash /tmp/av-eco/install.sh  # 현재 디렉토리에 설치
```

**설치 후 단계**:

```bash
# 1. Claude Code 재시작 (새 스킬 인식)

# 2. 생태계 건강도 확인
/av-vibe-forge health

# 3. settings.json 훅 병합 (기존 훅 있는 경우)
#    → Section 3.6 참조

# 4. CLAUDE.md 최신화
/av-base-sync update

# 5. 프로젝트 전용 에이전트 생성
/av-vibe-forge agent {service}-auditor --group {group} --inherits av-base-auditor
```

### 7.5 주기적 업데이트 워크플로우

```
{{PROJECT_NAME}} 업데이트 주기:
  1. 새 av- 컴포넌트 개발 완료
  2. /av-vibe-forge export --portable (av-export/ 갱신)
  3. rsync to GitHub repo + git push
  4. 의존 프로젝트에서 pull & 재설치

자동화 (GitHub Actions 예시):
  trigger: push to main ({{PROJECT_NAME}})
  action: export --portable → push to autovibe-ecosystem repo
```

---

## 8. FAQ

### Q: `/av-vibe-portable-init setup` 명령을 인식하지 못합니다

**원인**: `av-export/skills/`에 파일이 있지만 `.claude/skills/`에 없음. Claude Code는 `.claude/skills/`만 탐색.

**해결**: Section 3.6 "부트스트랩 수동 설치" 스크립트 실행 → Claude Code 재시작 → `/av-vibe-forge health` 확인.

---

### Q: {{PROJECT_NAME}}에서 업데이트된 컴포넌트를 다시 가져오려면?

```bash
# 1. {{PROJECT_NAME}}에서 재export
/av-vibe-forge export --portable

# 2. 대상 프로젝트로 rsync 동기화
rsync -av --delete {{PROJECT_ROOT}}/av-export/ /data/{target-project}/av-export/

# 3. 대상 프로젝트에서 재import (충돌 확인)
/av-vibe-forge import av-export/

# 4. 검증
/av-vibe-portable-init verify
```

### Q: 기존 스킬이 있는 프로젝트에 이식하려면?

```bash
# setup 실행 시 충돌 경고 → "병합" 선택
/av-vibe-portable-init setup
# → "기존 components.json이 있습니다. [덮어쓰기/병합/취소]"
# → "병합" 선택 시 av-vibe/base/util만 추가, 기존 항목 유지
```

### Q: {target-project}의 기존 Python/Oracle 훅과 충돌하지 않나요?

`setup` 중 **병합** 선택 시 기존 훅은 유지됩니다.
av-base-* 훅은 별도 항목으로 추가되므로 충돌 없음.

다만 `av-base-session-init.sh`이 기존 SessionStart 훅과 중복될 수 있음 →
`/av-vibe-portable-init verify`로 확인 후 필요 시 수동 통합.

### Q: av-do-orchestrator 같은 파이프라인 스킬을 새 프로젝트용으로 만들려면?

```bash
# av-do-orchestrator를 템플릿으로 참조하여 새 오케스트레이터 생성
/av-vibe-forge skill intent-pipeline-orchestrator --group intent
# → av-vibe-skill-forge가 av-skill-advanced.md.tmpl 기반으로 생성
```

### Q: naming-rules.md에 {{PROJECT_NAME}} 특화 예시가 남아있는데 제거해도 되나요?

**예, 제거하거나 프로젝트에 맞게 교체하세요.** {{PROJECT_NAME}} 예시는 참조용입니다.
`/av-vibe-portable-init customize` → "그룹 체계 재정의" 선택.

### Q: util 도구 중 일부만 설치하려면?

`setup` 실행 중 util 도구 선택 화면에서 개별 선택 가능.
또는 이식 후 불필요한 util 컴포넌트를 레지스트리에서 제거:
```bash
# components.json에서 해당 util 항목 삭제 후
/av-vibe-forge validate  # 무결성 검증
```

---

## 9. 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| 2026-02-24 | v4.0 | Sanitize/Hydrate 자동화 시스템 추가 — 14개 플레이스홀더, 5종 스택 프리셋, MEMORY 자동 초기화, sanitize-rules.json |
| 2026-02-24 | v3.4 | GitHub 저장소 기반 배포 워크플로우 추가 (Section 7), install.sh 스크립트, av-ecosystem docs 포함 |
| 2026-02-24 | v3.3 | 부트스트랩 수동 설치 가이드 추가 (Section 3.6), FAQ Q&A 추가 (setup 인식 불가 트러블슈팅) |
| 2026-02-24 | v3.2 | 4-tier 도메인 체계 전면 적용 (vibe/base/util), 컴포넌트 목록 36개로 갱신, {target-project} 이관 가이드 추가 |
| 2026-02-24 | v1.0 | 초기 작성 ({{PROJECT_NAME}} ERP → 신규 프로젝트 이식) |

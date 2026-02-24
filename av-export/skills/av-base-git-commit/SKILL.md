---
name: av-base-git-commit
description: |
  git 커밋 자동화 스킬. git status 조회, 변경사항 분석, Conventional Commits 형식
  커밋 메시지 자동 생성, stage → commit 단계적 실행.
  트리거: git commit, 커밋, commit, 변경사항 저장, stage
autovibe: true
version: "1.0"
created: "2026-02-22"
group: base
tier: null
inherits: null
argument-hint: "commit [message] | stage [--all | files...] | status | log [--n N]"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Bash, Task]
---

# av-base-git-commit — Git 커밋 자동화 스킬

> git status → stage → Conventional Commits 메시지 자동 생성 → commit 원스텝 실행.

## Arguments

| 인자 | 필수 | 설명 | 기본값 |
|------|:----:|------|--------|
| `commit` | — | 서브커맨드: 커밋 실행 | — |
| `stage` | — | 서브커맨드: 파일 스테이징 | — |
| `status` | — | 서브커맨드: git 상태 조회 | — |
| `log` | — | 서브커맨드: 커밋 이력 조회 | — |
| `[message]` | ❌ | 커밋 메시지 (생략 시 자동 생성) | auto |
| `--all` | ❌ | stage: 모든 변경 파일 스테이징 | false |
| `--n N` | ❌ | log: 조회 커밋 수 | 10 |

## Subcommands

### commit [message]

```
/av-base-git-commit commit "feat: 로그인 기능 추가"
/av-base-git-commit commit           # 메시지 자동 생성
```

커밋 메시지를 제공하면 즉시 commit 실행. 생략 시 `av-base-git-committer` 에이전트에게 메시지 생성 위임.

**단계**:
1. `git status --porcelain` 실행 → staged 파일 확인
2. staged 파일 없으면 → "스테이징된 파일 없음" 안내 + `stage --all` 제안
3. message 미제공 시 → Task로 `av-base-git-committer` 에이전트 호출 → 생성된 메시지 사용
4. 메시지 최종 확인 출력 (AskUserQuestion 없이 바로 실행)
5. `git commit -m "..."` 실행
6. 커밋 결과 요약 출력 (변경 파일 수, 커밋 해시)

### stage [--all | files...]

```
/av-base-git-commit stage --all
/av-base-git-commit stage src/app.ts src/lib/auth.ts
```

**단계**:
1. `git status` 실행 → 변경 파일 목록 조회
2. `--all` 시: `git add -A` (단, `.env*` 파일은 자동 제외)
3. files 지정 시: `git add {files}` 개별 스테이징
4. 스테이징 결과 출력 (파일 목록 + 상태)

### status

```
/av-base-git-commit status
```

**단계**:
1. `git status` → 브랜치 + 변경 파일 목록
2. `git diff --stat HEAD` → 변경 통계 (추가/삭제 라인)
3. Staged vs Unstaged 분류 표시

### log [--n N]

```
/av-base-git-commit log
/av-base-git-commit log --n 5
```

**단계**:
1. `git log --oneline -N` → 최근 N개 커밋 조회
2. 커밋 해시 + 메시지 + 날짜 표 형식 출력
3. 현재 브랜치 정보 포함

## 프로세스

```
시작 프로토콜 (protocols.md §1)
  ↓
STEP 1: Read 자신의 MEMORY.md → 프로젝트 커밋 패턴 로드
STEP 2: 서브커맨드 파싱 → commit | stage | status | log 분기
STEP 3: [commit] staged 파일 존재 확인 → 없으면 stage 유도
STEP 4: [commit] message 미제공 → av-git-committer에게 위임
STEP 5: git 명령 실행 (Bash)
STEP 6: 결과 요약 출력
  ↓
MEMORY.md 이력 업데이트
```

## Conventional Commits 형식 (자동 생성 기준)

| 타입 | 용도 | 예시 |
|------|------|------|
| `feat` | 신규 기능 | `feat(auth): JWT 토큰 갱신 로직 추가` |
| `fix` | 버그 수정 | `fix(slip): 전표 조회 페이지네이션 오류 수정` |
| `refactor` | 리팩토링 | `refactor(hcm): 직원 서비스 DI 패턴 적용` |
| `docs` | 문서 변경 | `docs: CLAUDE.md 스킬 테이블 업데이트` |
| `test` | 테스트 추가/수정 | `test(auth): 로그인 E2E 시나리오 추가` |
| `chore` | 설정/빌드 | `chore: {{PKG_MANAGER}} lockfile 업데이트` |
| `style` | 포맷/린트 | `style: {{LINTER_NAME}} 포맷 자동 수정` |
| `perf` | 성능 개선 | `perf(acc): 회계 조회 쿼리 인덱스 최적화` |

## 보안 규칙

- `.env*`, `*.pem`, `*.key`, `credentials.*` 파일은 **절대 자동 스테이징 금지**
- stage 단계에서 위 파일 감지 시 → 경고 출력 + 해당 파일 제외

## 실행 프로토콜 참조

- 시작/종료 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`

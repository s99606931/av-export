---
name: av-vibe-forge
description: |
  AutoVibe 마스터 오케스트레이터. av- 생태계의 생성/조회/검증/관리를
  14개 서브커맨드로 제공. 생성 서브커맨드는 전용 forge에 위임.
autovibe: true
version: "1.1"
created: "2026-02-21"
updated: "2026-02-21"
group: vibe
tier: meta
inherits: null
argument-hint: "<subcommand> [args] [--options]"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task]
---

# av-vibe-forge — AutoVibe Master Orchestrator

> {{PROJECT_NAME}} av- 생태계의 모든 컴포넌트를 생성·관리·검증하는 마스터 스킬.

## 서브커맨드 전체 (14종)

| # | 커맨드 | 유형 | 설명 |
|---|--------|------|------|
| 1 | `skill [name]` | 생성 | 스킬 생성 → av-vibe-skill-forge 위임 |
| 2 | `agent [name]` | 생성 | 에이전트 생성 → av-vibe-agent-forge 위임 |
| 3 | `hook [type] [name]` | 생성 | 훅 생성 → av-vibe-hook-forge 위임 |
| 4 | `rule [name]` | 생성 | 룰 파일 직접 생성 |
| 5 | `list [--group]` | 조회 | 레지스트리 전체 또는 그룹별 목록 |
| 6 | `validate [name]` | 검증 | 전체 또는 대상 컴포넌트 검증 |
| 7 | `spec` | 조회 | av-base-spec.md 표시 |
| 8 | `upgrade [name]` | 관리 | 부모 변경 → 자식 전파 |
| 9 | `health` | 진단 | 생태계 건강도 보고서 |
| 10 | `export [--portable] [--group]` | 이식 | 컴포넌트 내보내기 |
| 11 | `import [path]` | 이식 | 컴포넌트 가져오기 |
| 12 | `version [name]` | 조회 | 버전 이력 조회 |
| 13 | `tree` | 조회 | 상속 트리 시각화 |
| 14 | `audit-request` | 특수 | 신규 컴포넌트 생성 요청 처리 |

## 서브커맨드 상세

### 1-4. 생성 서브커맨드 (위임)

> 4개 forge 스킬은 위임(delegation) 관계 (상속 아님 — components.json `delegates-to` 필드)

```
/av-vibe-forge skill acc-code-gen --group {your-group} --inherits saas-code-gen
  → av-vibe-skill-forge 호출

/av-vibe-forge agent acc-auditor --group {your-group} --inherits av-base-auditor --scope "src/services/{service}/**"
  → av-vibe-agent-forge 호출

/av-vibe-forge hook PostToolUse acc-write-monitor --group {your-group}
  → av-vibe-hook-forge 호출

/av-vibe-forge rule acc-prisma-rules --group {your-group}
  → av-vibe-rule-forge 호출
```

### 4. rule [name]

```
→ av-vibe-rule-forge 위임 호출

/av-vibe-forge rule prisma-rules --group {your-group}
  → av-vibe-rule-forge 호출 (Rule .md 생성 + 레지스트리 등록)
```

### 5. list [--group]

```
1. Read .claude/registry/components.json
2. 필터: --group 없으면 전체
3. 출력 형식:
   Agent (N): av-base-auditor, av-vibe-vibecoder
   Skill  (N): av-vibe-skill-forge, av-vibe-agent-forge, av-vibe-hook-forge, av-vibe-forge
   Hook   (N): av-base-write-monitor
   Rule   (N): av-base-spec
```

### 6. validate [name]

```
1. Read components.json → 대상 특정 (없으면 전체)
2. 각 컴포넌트에 대해:
   - Read 파일 → frontmatter 필수 필드 확인
   - av- 네이밍 6대 규칙 검증
   - --inherits 시: 부모 존재, scope Liskov, children 등록
   - autovibe: true 존재 확인
3. PASS/FAIL 리포트 출력
```

### 7. spec

```
1. Read .claude/rules/av-base-spec.md
2. 필요 시 AskUserQuestion → 특정 topic 선택
3. Read .claude/docs/av-claude-code-spec/topics/{topic}.md
4. 내용 출력
```

### 8. upgrade [name]

```
1. Read components.json → 대상 + children 목록
2. Read 부모 파일 → 변경 섹션 식별
3. Read 각 자식 파일 → 충돌 여부 확인
4. 충돌 없음: Edit 자식 파일 자동 업데이트
   충돌 있음: AskUserQuestion → 병합 방식 결정
5. validate 자동 실행
6. av-base-auditor 감사 요청 (Level 3)
```

### 9. health

```
1. Glob .claude/{agents,skills,hooks,rules}/**
2. Read components.json
3. 교차 검증:
   - 파일 있음 + 미등록 → UNREGISTERED
   - 등록 있음 + 파일 없음 → MISSING
   - 메모리 없는 컴포넌트 → NO_MEMORY
   - 상속 depth > 3 → DEPTH_VIOLATION
   - 고아 노드(부모 없음) → ORPHAN
4. 건강도 요약:
   [OK] N개 | [UNREGISTERED] N개 | [MISSING] N개 | [NO_MEMORY] N개
5. 이슈 목록 + 권장 조치 출력
```

### 10. export [--portable] [--group]

```
1. Read components.json → 수집 대상 결정
   --portable: portable === true (domain in [vibe, base, util])
   --group {g}: 해당 그룹만
2. mkdir -p av-export/{skills,agents,hooks,rules,docs,templates}

--portable 필터링 기준:
  조건 1: portable === true (components.json 필드)
  이름 기반: av-vibe-* → 항상이식, av-base-* → 항상이식, av-util-* → 선택이식
  제외:   av-erp-*, av-do-*, av-legacy-*, av-acc-* (프로젝트 전용)

--portable 포함 대상 (36개):
  Rules (3):   av-base-spec, av-base-memory-first, av-util-mermaid-std
  Skills (19): av, av-vibe-forge, av-vibe-skill-forge, av-vibe-agent-forge,
               av-vibe-hook-forge, av-vibe-rule-forge, av-vibe-migrator,
               av-vibe-portable-init, av-base-code-quality, av-base-git-commit,
               av-base-sync, av-base-refactor, av-base-post-qa,
               av-util-redis, av-util-shadcn, av-util-mermaid,
               av-util-dev-guide, av-util-e2e-doc, av-util-tech-guide
  Agents (9):  av-base-auditor, av-vibe-vibecoder, av-base-optimizer,
               av-base-quality-auditor, av-base-git-committer, av-base-sync-auditor,
               av-base-refactor-advisor, av-base-qa-reviewer, av-base-template
  Hooks (5):   av-base-bash-guard, av-base-content-scan, av-base-session-init,
               av-base-write-monitor, av-base-precommit-sync
  추가 포함:
    docs/av-claude-code-spec/topics/*.md (4개 topic 파일)
    docs/av-ecosystem/*.md (5개 생태계 개발자 문서)
    templates/av-docs/*.tmpl (16개 템플릿 — av-memory-init-*.md.tmpl 포함)
    docs/av-portable-guide.md (이식 가이드)
    skills/av-vibe-forge/sanitize-rules.json (정화 규칙)
    install.sh (자동 설치 스크립트 — GitHub 배포용)

3. cp 대상 파일 → av-export/

★ 4. Sanitize (--portable 모드 전용)
  4a. Read .claude/skills/av-vibe-forge/sanitize-rules.json → 정화 규칙 로드
  4b. 플레이스홀더 치환 — av-export/ 내 모든 .md 파일 대상:
      - placeholders 배열의 allsaas_values/patterns → {{PLACEHOLDER_ID}} 로 치환
      - 치환 우선순위: 긴 패턴 먼저 (예: "{{BACKEND_FRAMEWORK}}+Fastify+{{ORM_NAME}} 7" → "{{BACKEND_FRAMEWORK}}")
      - 치환 대상 예시:
          {{PROJECT_NAME}}                    → {{PROJECT_NAME}}
          {{PROJECT_ROOT}}             → {{PROJECT_ROOT}}
          {{PROJECT_SRC}}            → {{PROJECT_SRC}}
          {{PACKAGE_SCOPE}}                   → {{PACKAGE_SCOPE}}
          {{BACKEND_FRAMEWORK}}+Fastify+{{ORM_NAME}} 7 → {{BACKEND_FRAMEWORK}}+Fastify+{{ORM_NAME}} 7
          {{FRONTEND_FRAMEWORK}}+React 19        → {{FRONTEND_FRAMEWORK}}+React 19
          {{ORM_NAME}} 7                   → {{ORM_NAME}} 7
          {{MESSAGING_SYSTEM}} 2.12                  → {{MESSAGING_SYSTEM}} 2.12
          {{MONOREPO_TOOL}}                  → {{MONOREPO_TOOL}}
          {{LINTER_NAME}} 2                    → {{LINTER_NAME}} 2
          {{PKG_MANAGER}}                → {{PKG_MANAGER}}
          {{BUILD_COMMAND}}       → {{BUILD_COMMAND}}
          {{MULTI_TENANT_FIELD}}                   → {{MULTI_TENANT_FIELD}}
          {{PROJECT_DOMAIN}}           → {{PROJECT_DOMAIN}}
  4c. 프로젝트 전용 섹션 제거 (section_removals 규칙 적용):
      - av-portable-guide.md: "## 3. {target-project} 이관 가이드" 섹션 제거
        → "## 3. 이식 후 설정 가이드\n> 각 프로젝트별 맞춤화 필요" 로 교체
  4d. ERP 예시 → 범용 예시 치환 (example_replacements 적용):
      - "allsaas.{tier}.{module}..." → "{project}.{tier}.{module}..."
      - "--group {your-group}" → "--group {your-group}"
      - "--scope \"services/core/acc/**\"" → "--scope \"src/services/{service}/**\""
  4e. MEMORY.md 완전 초기화:
      - Glob: av-export/skills/*/MEMORY.md → 각 파일을 av-memory-init-skill.md.tmpl 기반으로 재생성
        (SKILL_NAME, GROUP 필드는 frontmatter에서 추출)
      - Glob: av-export/agent-memory/*/MEMORY.md → av-memory-init-agent.md.tmpl 기반으로 재생성
        (AGENT_NAME, GROUP, INHERITS 필드는 각 에이전트 .md 파일에서 추출)
  4f. components.json scope 필드 치환:
      - components_json_sanitize.scope_replacements 규칙 적용
      - av-export/portable-components.json의 scope 필드 일괄 치환
  4g. sanitize-report.json 생성:
      {
        sanitized_at: ISO8601,
        placeholder_substitutions: {total: N, by_placeholder: {PROJECT_NAME: N, ...}},
        sections_removed: N,
        example_replacements: N,
        memory_files_reset: {skills: N, agents: N},
        files_processed: N,
        warnings: ["치환 실패 파일 목록"] // 있을 경우
      }

5. Write av-export/portable-components.json
   (portable=true 컴포넌트만 포함하는 필터링된 레지스트리)
6. Write av-export/export-manifest.json
   {
     exported_at: ISO8601,
     source_project: "{{PROJECT_NAME}}",  // sanitize 후 플레이스홀더
     mode: "--portable",
     sanitized: true,
     placeholder_count: 14,
     filter: "portable=true AND domain in [vibe, base, util]",
     domain_taxonomy: {vibe: "생태계 핵심 도구", base: "범용 필수 도구", util: "범용 선택 도구"},
     components: {agents: N, skills: N, hooks: N, rules: N, total: N},
     extras: {docs_topics: N, docs_ecosystem: 5, templates: N,
              portable_guide: "docs/av-portable-guide.md",
              ecosystem_docs: "docs/av-ecosystem/",
              sanitize_rules: "skills/av-vibe-forge/sanitize-rules.json",
              sanitize_report: "sanitize-report.json",
              install_script: "install.sh"},
     install_command: "bash install.sh",
     hydrate_command: "/av-vibe-portable-init setup",
     github_workflow: "git clone REPO /tmp/av && bash /tmp/av/install.sh --target PROJECT"
   }
7. install.sh 생성 (자동 설치 스크립트 — GitHub 배포용)
8. 완료 메시지:
   "✅ portable 패키지 생성 + 정화(Sanitize) 완료 → av-export/
    ─────────────────────────────────
    정화 결과: av-export/sanitize-report.json 참조
    플레이스홀더 치환: N건 | 섹션 제거: N건 | MEMORY 초기화: N개
    ─────────────────────────────────
    이식 방법 A: bash av-export/install.sh → /av-vibe-portable-init setup (로컬)
    이식 방법 B: GitHub에 push 후 curl 원라인 (원격)
    상세: .claude/docs/av-portable-guide.md"
```

### 11. import [path]

```
1. Read {path}/export-manifest.json
2. AskUserQuestion → 임포트 대상 선택, 충돌 처리 방식
3. cp 선택된 파일 → .claude/ 경로
4. Edit components.json → 신규 등록
5. validate 자동 실행
```

### 12. version [name|--all]

```
1. Read .claude/registry/components.json → 버전 확인
2. Read 해당 컴포넌트 MEMORY.md → "변경 이력" 섹션
3. 버전 이력 테이블 출력
```

### 13. tree

```
1. Read components.json → inherits/children 관계 파싱
2. 트리 텍스트 렌더링:

   [base]
   └── av-base-auditor (v1.0)
       └── av-acc-auditor (v1.0)
   [vibe]
   └── av-vibe-forge (v1.0)
       └── av-vibe-skill-forge (v1.0)
```

### 14. audit-request

av-base-auditor가 NEED_NEW 판정 시 호출하는 특수 서브커맨드:

```
1. 감사 요청 정보 수신:
   {type: skill|agent|hook|rule, name, reason, priority}
2. AskUserQuestion → 사용자 생성 승인 확인
3. 승인 시: 해당 forge 서브커맨드 호출
4. 거절 시: 이력 기록만
```

## 마스터 실행 프로토콜

```
시작:
  1. Read .claude/skills/av-vibe-forge/MEMORY.md
  2. Read 글로벌 MEMORY.md → 프로젝트 컨텍스트
  3. 인자 파싱 → 서브커맨드 + 옵션 분리

종료:
  생성/수정 서브커맨드(1-4,8,11,14): av-base-auditor Level 3 감사 요청
  조회/표시 서브커맨드(5,7,12,13):   Level 1 Self-Check만
  validate(6), health(9), export(10): Level 2 감사
  MEMORY.md 이력 업데이트
```

## 실행 프로토콜 참조

- 프로토콜: `.claude/docs/av-claude-code-spec/topics/protocols.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`
- 네이밍: `.claude/docs/av-claude-code-spec/topics/naming-rules.md`

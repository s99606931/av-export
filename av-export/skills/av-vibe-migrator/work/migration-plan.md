# AutoVibe 마이그레이션 계획서

> 스캔 일시: 2026-02-24
> 스캐너: av-vibe-migrator scan

## 요약

| 분류 | 개수 | 설명 |
|------|-----:|------|
| SKIP | 53 | 이미 AutoVibe 완료 (변경 불필요) |
| REGISTER | 29 | 이미 레지스트리 등록됨 (autovibe:false — 의도적) |
| MIGRATE | 0 | av- 전환 필요 없음 |
| CONSOLIDATE | 0 | 통합 대상 없음 |
| DELETE | 0 | 삭제 대상 없음 |

**판정: 마이그레이션 불필요. 생태계 100% 정합.**

## SKIP (53개) — AutoVibe 완료

### Agents (26개 — autovibe:true)
- av-acc-auditor, av-auditor, av-claude-sync-auditor
- av-do-api-spec-agent, av-do-backend-agent, av-do-db-agent, av-do-e2e-agent, av-do-orchestrator
- av-erp-backend-guard, av-erp-fe-auditor, av-erp-frontend-guard, av-erp-infra-guard
- av-erp-migration-qa, av-erp-migrator, av-erp-quality-guard, av-erp-uiux-guard
- av-git-committer, av-legacy-func-analyzer, av-optimizer, av-oracle-schema-mapper
- av-post-qa-reviewer, av-quality-auditor, av-refactor-advisor
- av-ui-i18n-guard, av-uiux-blueprint-generator, av-vibe-vibecoder

### Skills (22개 — autovibe:true)
- av, av-claude-sync, av-code-quality, av-do-orchestrator, av-e2e-ui-tester
- av-erp-fe-audit, av-erp-migration, av-erp-uiux-dev, av-git-commit
- av-legacy-blueprint, av-post-qa, av-refactor
- av-vibe-agent-forge, av-vibe-forge, av-vibe-hook-forge, av-vibe-migrator, av-vibe-rule-forge, av-vibe-skill-forge

### Hooks (5개 — autovibe:true)
- av-bash-guard, av-content-scanner, av-post-write-monitor
- av-pre-commit-docs-sync, av-session-discovery

### Rules (4개 — 등록됨)
- av-api-response-patterns, av-claude-code-spec
- mcp-memory-first, mermaid-standard

## REGISTER (29개) — 등록됨, autovibe:false (의도적 비AutoVibe)

> 이 컴포넌트들은 레지스트리에 이미 등록되어 있으나 autovibe:false입니다.
> {{PROJECT_NAME}} 프로젝트 도메인 스킬/에이전트로 AutoVibe 네이밍 규칙 적용 불필요.
> **액션 없음 — 현 상태 유지.**

### Agents (5개)
- build-stabilizer, docker-orchestrator, env-validator, integration-tester, template-agent

### Skills (24개)
- db-query, dev-guide-gen, docs-sync, e2e-doc-gen, erp-quality, infra-build
- legacy-analyzer, mermaid, prisma-manage, redis-ops, saas-code-gen, saas-doc-gen
- saas-review, saas-test, service-integrator, shadcn-ref, tech-learning-guide-gen
- template-manager, ui-ux-dev, ui-ux-expert
- verify-common-exports, verify-implementation, verify-nestjs-patterns, verify-prisma-conventions

## 결론

생태계 마이그레이션 완전 완료. 모든 av- 컴포넌트가 AutoVibe 표준 준수.
비av- 컴포넌트(29개)는 도메인 스킬로 현 상태 유지 권장.

→ 다음 권장 액션: `/av health` 로 최종 건강도 점수 확인

# Audit Rules — 계층별 감사 + 셀프 체크 + 면제

> Plan §3.3, §3.4, §3.5 참조.

## 1. 계층별 감사 전략 (Tiered Auditing)

### 3단계 감사 수준

| 수준 | 대상 | 방식 | 체크 항목 | 소요 |
|------|------|------|---------|------|
| L1 경량 | MEMORY.md 업데이트, 설정 변경, 문서 수정 | Self-Check (auditor 미호출) | 포맷, 200줄 제한, 중복 | ~5초 |
| L2 표준 | 코드 변경, 스킬/에이전트 body 수정, 비즈니스 로직 | av-base-auditor 호출 | L1 + 로직 정확성 + 컨벤션 | ~30초 |
| L3 구조 | 신규 컴포넌트 생성, 상속 변경, 레지스트리 수정, CLAUDE.md 변경 | av-base-auditor + 레지스트리 검증 | L2 + 상속 트리 + 레지스트리 정합성 | ~60초 |

### 자동 결정 로직

```
IF changed_files 중 MEMORY.md만 있음 → Level 1
ELSE IF changed_files에 agents/ OR skills/ OR registry/ 포함 → Level 3
ELSE → Level 2
```

## 2. 감사 체크리스트 (av-base-auditor 수행)

### 체크 1: 포맷 준수

```
에이전트:
  ✓ name, description, autovibe, version, tools, model, scope 필드 존재
  ✓ av- 접두사 + kebab-case + 최대 4단어
  ✓ autovibe: true

스킬:
  ✓ name, description, autovibe, version, argument-hint, user-invocable, allowed-tools
  ✓ av- 접두사 + kebab-case

훅:
  ✓ #!/bin/bash 셔뱅 + 메타 주석 (name, autovibe, version, hook-type)
  ✓ stdin 파싱 + JSON stdout + exit 0
```

### 체크 2: 메모리 저장 품질

```
✓ 작업 에이전트/스킬의 MEMORY.md 업데이트 여부
✓ 핵심 내용의 글로벌 메모리 전파 적절성
✓ work 세션 파일 완성도 (멀티에이전트 시)
```

### 체크 3: 로직 정확성

```
✓ 작업 목표와 결과 일치
✓ {{PROJECT_NAME}} 컨벤션 준수:
  - {{ORM_NAME}} 7 규칙 ({{MULTI_TENANT_FIELD}}, deletedAt, ~7.3 버전)
  - {{BACKEND_FRAMEWORK}} 패턴 (Fastify, 모듈 구조, DI)
  - API 표준 (RFC 7807, /api/v1/{module}/{domain})
  - import type 금지 (DI 클래스)
```

### 체크 4: 신규 컴포넌트 필요성

```
✓ 보고된 필요성 타당성 검토
✓ 기존 컴포넌트로 대체 가능 여부
✓ 타당하면 av-vibe-forge audit-request 호출
```

## 3. 셀프 체크리스트 (Self-Check L1, §3.5)

모든 코드/파일 변경 완료 후 스스로 확인:

```
[ ] 보안: 사용자 입력 검증, SQL injection 방지, 하드코딩 비밀키 없음
[ ] 에러: try-catch 누락 없음, 빈 catch 블록 없음
[ ] 타입: any 최소화, import type 올바른 사용 (DI 클래스에 import type 금지)
[ ] 테스트: 변경된 로직에 대한 테스트 존재 여부
[ ] 컨벤션: {{ORM_NAME}} 7, {{BACKEND_FRAMEWORK}} 패턴, API 표준, av- 네이밍 준수
```

## 4. 감사 면제 규칙

### av-base-auditor 자기 감사 면제 (순환 참조 방지)

```
av-base-auditor 자체 변경:
  → Level 1 Self-Check만 수행 (auditor 미호출)
  → 구조적 변경(body/scope 변경) 시 AskUserQuestion으로 사용자 확인 필수
  → 변경 이력을 자신의 MEMORY.md에 기록

av-base-post-qa / av-base-qa-reviewer 자체 변경:
  → Level 1 Self-Check만 수행 (자기 감사 면제 — 순환 참조 방지)
  → STEP 7 대량 작업 판정에서도 QA 생략 대상

av-vibe-forge가 av-base-auditor 업그레이드 시:
  → av-vibe-forge가 변경 수행
  → Level 1 Self-Check (auditor는 자기 변경 감사 불가)
  → AskUserQuestion으로 사용자 최종 확인
```

## 5. 감사 결과 유형

| 결과 | 의미 | 후속 행동 |
|------|------|---------|
| PASS | 모든 체크 통과 | STEP 7 대량 작업 판정 진행 → 대량 작업이면 av-base-post-qa review 자동 호출, 아니면 업무 종료 |
| FAIL | 체크 미통과 | 수정 요청 + 구체적 피드백. 최대 3회 재작업 후 에스컬레이션 |
| NEED_NEW | 신규 컴포넌트 필요 | av-vibe-forge audit-request 호출 |

### PASS 후 대량 작업 판정 흐름 (STEP 7)

```
av-base-auditor PASS
  ↓
대량 작업 판정:
  (a) changed_files >= 10개?
  (b) batch_info.total_items >= 5개?
  (c) task_type ∈ {batch, migration, generation, bulk, wave, run-all}?

  → 하나 이상 해당 + 예외 없음 → /av-base-post-qa review 호출
  → 해당 없음 또는 예외 해당 → 업무 종료

예외 (QA 생략):
  - MEMORY.md만 변경 (L1 Self-Check 충분)
  - av-base-post-qa / av-base-qa-reviewer 자체 변경 (자기 감사 면제)
```

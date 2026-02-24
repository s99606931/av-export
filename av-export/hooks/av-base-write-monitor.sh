#!/bin/bash
# name: av-base-write-monitor
# autovibe: true
# version: 1.2
# created: 2026-02-21
# updated: 2026-02-22
# hook-type: PostToolUse
# trigger-tools: Write, Edit
# description: 파일 변경 로그 기록 + 확장자별 빠른 검증 (ts/prisma/md) + 에이전트 라우팅 제안 + 리팩토링 기회 감지

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "unknown")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# 변경 로그 기록
LOG_FILE=".claude/work/change-log.txt"
mkdir -p "$(dirname "$LOG_FILE")"
if [ -n "$FILE_PATH" ]; then
  echo "$(date +%Y-%m-%dT%H:%M:%S) $TOOL_NAME $FILE_PATH" >> "$LOG_FILE"
fi

# 확장자별 경량 검증
MSG=""
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  case "$FILE_PATH" in
    *.ts|*.tsx)
      # TypeScript: import type 위반 빠른 검사
      if grep -qP 'import\s+type\s+\{[^}]*Service' "$FILE_PATH" 2>/dev/null; then
        MSG="[DI] import type for Service detected in $FILE_PATH — NestJS DI 크래시 위험"
      fi
      ;;
    *.prisma)
      # Prisma: provider 검사
      if grep -q 'provider\s*=\s*"prisma-client-js"' "$FILE_PATH" 2>/dev/null; then
        MSG="[PRISMA] provider should be \"prisma-client\" not \"prisma-client-js\" in $FILE_PATH"
      fi
      ;;
    *.md)
      # Markdown: av- 파일 frontmatter description 필드 확인
      if [[ "$FILE_PATH" == *av-* ]]; then
        if head -20 "$FILE_PATH" 2>/dev/null | grep -q '^---' && \
           ! head -20 "$FILE_PATH" 2>/dev/null | grep -q 'description:'; then
          MSG="[FRONTMATTER] Missing description field in av- component: $FILE_PATH"
        fi
      fi
      ;;
  esac
fi

# ── 에이전트 라우팅 제안 (경량 검증 오류 없을 때만) ────────────────────────
AGENT_HINT=""

if [ -z "$MSG" ] && [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  # auth/guards/security 패턴 우선 검사 (보안 파일은 quality-guard)
  if echo "$FILE_PATH" | grep -qE '/(auth|guards|security|interceptors)/'; then
    AGENT_HINT="[GUARD] av-erp-quality-guard 리뷰 권장 — 보안 관련 파일 변경: $(basename "$FILE_PATH")"
  else
    case "$FILE_PATH" in
      *.module.ts|*.controller.ts|*.service.ts|*.prisma)
        AGENT_HINT="[GUARD] av-erp-backend-guard 리뷰 권장 — NestJS/Prisma 변경: $(basename "$FILE_PATH")"
        ;;
      *.tsx|*.jsx)
        AGENT_HINT="[GUARD] av-erp-frontend-guard 리뷰 권장 — Frontend 변경: $(basename "$FILE_PATH")"
        ;;
      *.spec.ts|*.test.ts|*.e2e-spec.ts)
        AGENT_HINT="[GUARD] av-erp-quality-guard 리뷰 권장 — 테스트 파일 변경: $(basename "$FILE_PATH")"
        ;;
      *docker-compose*|*Dockerfile*)
        AGENT_HINT="[GUARD] av-erp-infra-guard 리뷰 권장 — 인프라 파일 변경: $(basename "$FILE_PATH")"
        ;;
    esac
  fi
fi

# ── 리팩토링 기회 감지 (에이전트 가드 힌트 없을 때, 서비스 파일 구현 시) ─────
REFACTOR_HINT=""

if [ -z "$MSG" ] && [ -z "$AGENT_HINT" ] && [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  # 새 서비스 구현 파일 감지 (새로 작성된 service.ts 파일)
  case "$FILE_PATH" in
    *.service.ts)
      # findAll/findOne 패턴 중복 감지 (간단 휴리스틱)
      LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
      if [ "$LINE_COUNT" -gt 80 ]; then
        REFACTOR_HINT="[REFACTOR] av-base-refactor-advisor 리팩토링 분석 권장 — 대형 서비스 파일(${LINE_COUNT}줄): $(basename "$FILE_PATH")"
      fi
      ;;
    *.tsx)
      # 대형 컴포넌트 감지
      LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
      if [ "$LINE_COUNT" -gt 120 ]; then
        REFACTOR_HINT="[REFACTOR] av-base-refactor-advisor 리팩토링 분석 권장 — 대형 컴포넌트(${LINE_COUNT}줄): $(basename "$FILE_PATH")"
      fi
      ;;
  esac
fi

# 출력: 경량 검증 오류 우선, 없으면 에이전트 힌트, 없으면 리팩토링 힌트
FINAL_MSG="${MSG:-${AGENT_HINT:-$REFACTOR_HINT}}"
if [ -n "$FINAL_MSG" ]; then
  echo "{\"systemMessage\":\"av-post-write-monitor: $FINAL_MSG\"}"
else
  echo "{}"
fi
exit 0

#!/bin/bash
# name: av-base-precommit-sync
# autovibe: true
# version: 1.1
# created: 2026-02-22
# hook-type: PreToolUse
# trigger-tools: Bash
# description: git commit 전 CLAUDE.md 문서 동기화 여부 경고 — 구조적 변경 감지 시 /docs-sync 실행 유도

# stdin에서 JSON 입력 읽기 (실패해도 계속 진행)
INPUT=$(cat 2>/dev/null || echo '{}')

# python3로 안전하게 command 추출 (grep/sed보다 신뢰성 높음)
COMMAND=""
if command -v python3 &>/dev/null; then
  COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', data).get('command', '')
    print(cmd)
except Exception:
    pass
" 2>/dev/null || echo "")
else
  # fallback: grep/sed (단순 명령어만 처리)
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

# git commit 명령이 아니면 즉시 허용 — allow는 exit 0으로 충분 (공식 스펙)
if ! echo "$COMMAND" | grep -qE '^git commit' 2>/dev/null; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT_SCRIPT="${SCRIPT_DIR}/../scripts/detect-structure-changes.sh"

# 감지 스크립트가 없으면 허용
if [ ! -f "$DETECT_SCRIPT" ]; then
  exit 0
fi

# 구조 변경 감지 실행 (staged 파일만 확인 - 커밋하려는 파일 대상)
result=$("$DETECT_SCRIPT" --staged 2>/dev/null || echo '{"needsSync": false}')

needs_sync=$(echo "$result" | grep -o '"needsSync": true' 2>/dev/null || true)

if [ -n "$needs_sync" ]; then
  # deny: hookSpecificOutput 형식 사용 (공식 최신 스펙)
  # 출처: https://code.claude.com/docs/en/hooks#pretooluse-decision-control
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"CLAUDE.md 동기화 필요 - 구조적 변경이 감지되었습니다. 커밋 전에 /docs-sync check 를 실행하여 CLAUDE.md를 업데이트하세요."}}'
  exit 0  # 반드시 exit 0 — deny 후 allow가 추가 출력되는 버그 방지
fi

# 구조 변경 없음 — allow는 exit 0으로 충분
exit 0

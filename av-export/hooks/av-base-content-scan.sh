#!/bin/bash
# name: av-base-content-scan
# autovibe: true
# version: 1.3
# created: 2026-02-21
# updated: 2026-02-22
# hook-type: PreToolUse
# trigger-tools: Write, Edit
# description: 위험 패턴 감지 (import type 위반, SQL injection, XSS, 하드코딩 비밀키)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# 파일이 없거나 TypeScript/TSX 파일 아니면 통과
# 항상 JSON {} 출력 — 빈 stdout은 Claude Code가 JSON 파싱 실패로 처리할 수 있음
[ -z "$FILE_PATH" ] && echo '{}' && exit 0
[ ! -f "$FILE_PATH" ] && echo '{}' && exit 0

case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) echo '{}' && exit 0 ;;
esac

W=""
C=$(cat "$FILE_PATH" 2>/dev/null || echo "")

# [HIGH] NestJS DI: import type 금지 (런타임 크래시)
if echo "$C" | grep -qP 'import\s+type\s+\{[^}]*Service' 2>/dev/null; then
  W="${W}[DI] import type for Service — NestJS DI 런타임 크래시. "
fi

# [CRITICAL] SQL injection 위험
if echo "$C" | grep -q '\$queryRawUnsafe' 2>/dev/null; then
  W="${W}[SQL] \$queryRawUnsafe 감지 → \$queryRaw + 파라미터 바인딩 사용. "
fi

# [HIGH] XSS 위험
if echo "$C" | grep -q 'dangerouslySetInnerHTML' 2>/dev/null; then
  W="${W}[XSS] dangerouslySetInnerHTML 감지 → DOMPurify 적용 필요. "
fi

# [CRITICAL] 하드코딩 비밀키 (TypeScript 타입 어노테이션 포함: apiKey: string = "...")
if echo "$C" | grep -qP '(password|secret|apiKey|api_key|privateKey)\s*(?::\s*\w+\s*)?=\s*"[^"]{8,}"' 2>/dev/null; then
  W="${W}[SEC] 하드코딩 비밀키 감지 → 환경변수 사용. "
fi

# 항상 JSON 출력: 경고 있으면 systemMessage, 없으면 빈 {}
# av-post-write-monitor.sh와 동일 패턴 — 빈 stdout 방지
if [ -n "$W" ]; then
  printf '{"systemMessage":"av-content-scanner: %s"}' "$W"
else
  echo '{}'
fi
exit 0

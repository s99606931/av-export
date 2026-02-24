#!/bin/bash
# name: av-base-bash-guard
# autovibe: true
# version: 1.1
# created: 2026-02-21
# hook-type: PreToolUse
# trigger-tools: Bash
# description: Bash 위험 명령 차단 (DENY) 및 경고 (WARN) — 비가역적 파괴적 명령 방지

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

# Bash 도구만 처리 — allow는 exit 0으로 충분 (공식 스펙)
[ "$TOOL_NAME" != "Bash" ] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
[ -z "$CMD" ] && exit 0

DENY_REASON=""
WARN_MSG=""

# ─── DENY: 절대 실행 금지 (비가역적 재앙) ───────────────────────────────

# 루트/홈 디렉토리 강제 삭제
if echo "$CMD" | grep -qP 'rm\s+-[a-z]*r[a-z]*f\s+(/\s*$|/\s+|~/\s*$|~/\s+)' 2>/dev/null; then
  DENY_REASON="rm -rf / 또는 rm -rf ~/ 감지 — 시스템 파일 삭제 위험. 명시적 경로 지정 필요"
fi

# 시스템 파일 덮어쓰기
if echo "$CMD" | grep -qP '>\s*/etc/(passwd|shadow|sudoers|hosts)' 2>/dev/null; then
  DENY_REASON="시스템 파일(/etc/passwd 등) 덮어쓰기 감지 — 운영체제 손상 위험"
fi

# init/systemd kill (컨테이너도 포함)
if echo "$CMD" | grep -qP 'kill\s+-9\s+1\b' 2>/dev/null; then
  DENY_REASON="kill -9 1 감지 — init/systemd 종료 위험"
fi

# DB 전체 삭제
if echo "$CMD" | grep -qiP 'DROP\s+DATABASE\s+\w+' 2>/dev/null; then
  DENY_REASON="DROP DATABASE 감지 — 데이터베이스 전체 삭제 위험. psql을 통한 직접 실행 필요"
fi

# ─── WARN: 경고 후 허용 (주의 필요) ─────────────────────────────────────

if [ -z "$DENY_REASON" ]; then
  WARNS=""

  # rm -rf (일반)
  if echo "$CMD" | grep -qP 'rm\s+-[a-z]*r[a-z]*f' 2>/dev/null; then
    WARNS="${WARNS}[WARN] rm -rf 감지 — 복구 불가. 경로 재확인 권장. "
  fi

  # git reset --hard
  if echo "$CMD" | grep -qP 'git\s+reset\s+--hard' 2>/dev/null; then
    WARNS="${WARNS}[WARN] git reset --hard 감지 — 미커밋 변경사항 소실. stash 여부 확인 권장. "
  fi

  # git push --force
  if echo "$CMD" | grep -qP 'git\s+push\s+.*(-f|--force)' 2>/dev/null; then
    if echo "$CMD" | grep -qP '(main|master)' 2>/dev/null; then
      WARNS="${WARNS}[WARN] main/master 강제 푸시 감지 — 원격 기록 삭제 위험. PR/Review 프로세스 우회 금지. "
    else
      WARNS="${WARNS}[WARN] git push --force 감지 — 원격 커밋 덮어쓰기. 공유 브랜치 여부 확인. "
    fi
  fi

  # git clean -f
  if echo "$CMD" | grep -qP 'git\s+clean\s+-[a-z]*f' 2>/dev/null; then
    WARNS="${WARNS}[WARN] git clean -f 감지 — 미추적 파일 영구 삭제. -n 플래그로 dry-run 먼저 확인 권장. "
  fi

  # docker system prune
  if echo "$CMD" | grep -qP 'docker\s+(system\s+)?prune' 2>/dev/null; then
    WARNS="${WARNS}[WARN] docker prune 감지 — 빌드 캐시/이미지 대량 삭제. 공유 환경 영향 확인. "
  fi

  # DROP TABLE
  if echo "$CMD" | grep -qiP 'DROP\s+TABLE' 2>/dev/null; then
    WARNS="${WARNS}[WARN] DROP TABLE 감지 — 테이블 영구 삭제. 마이그레이션 파일로 관리 권장. "
  fi

  WARN_MSG="$WARNS"
fi

# ─── 응답 출력 (공식 최신 스펙 준수) ──────────────────────────────────────
# 출처: https://code.claude.com/docs/en/hooks#pretooluse-decision-control
# - allow: exit 0으로 충분 (JSON 불필요)
# - deny:  hookSpecificOutput.permissionDecision = "deny"
# - warn:  systemMessage (universal top-level 필드)

if [ -n "$DENY_REASON" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"av-bash-guard: %s"}}' "$DENY_REASON"
elif [ -n "$WARN_MSG" ]; then
  printf '{"systemMessage":"av-bash-guard: %s"}' "$WARN_MSG"
fi
# allow: 아무것도 출력하지 않고 exit 0
exit 0

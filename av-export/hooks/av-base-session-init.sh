#!/bin/bash
# name: av-base-session-init
# autovibe: true
# version: 1.0
# created: 2026-02-21
# hook-type: SessionStart
# trigger-tools: (session start)
# description: 세션 시작 시 AutoVibe 생태계 상태 주입 (~30 토큰)

REGISTRY=".claude/registry/components.json"

if [ -f "$REGISTRY" ] && command -v jq &>/dev/null; then
  AGENT_COUNT=$(jq -r '._meta.total.agents // 0' "$REGISTRY" 2>/dev/null || echo 0)
  SKILL_COUNT=$(jq -r '._meta.total.skills // 0' "$REGISTRY" 2>/dev/null || echo 0)
  HOOK_COUNT=$(jq -r '._meta.total.hooks // 0' "$REGISTRY" 2>/dev/null || echo 0)
  RULE_COUNT=$(jq -r '._meta.total.rules // 0' "$REGISTRY" 2>/dev/null || echo 0)
  echo "{\"systemMessage\":\"AutoVibe 생태계 활성화: Agent ${AGENT_COUNT}개, Skill ${SKILL_COUNT}개, Hook ${HOOK_COUNT}개, Rule ${RULE_COUNT}개. 사용: /av-vibe-forge health\"}"
else
  echo "{\"systemMessage\":\"AutoVibe 미초기화. /av-vibe-forge health 실행 권장.\"}"
fi
exit 0

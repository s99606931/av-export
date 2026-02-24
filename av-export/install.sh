#!/bin/bash
# AutoVibe Ecosystem Installer
# 사용법:
#   로컬: bash install.sh [--target /path/to/project]
#   원격: curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/autovibe-ecosystem/main/install.sh | bash
#
# 설치 후: Claude Code 재시작 → /av-vibe-portable-init setup → /av-vibe-forge health

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(pwd)}"
# --target 옵션 처리
if [ "$1" = "--target" ] && [ -n "$2" ]; then
  TARGET="$2"
fi
CLAUDE_DIR="$TARGET/.claude"

echo "════════════════════════════════════════════"
echo "  AutoVibe Ecosystem Installer"
echo "════════════════════════════════════════════"
echo "  대상: $CLAUDE_DIR"
echo "────────────────────────────────────────────"

# 1. 디렉토리 생성
mkdir -p "$CLAUDE_DIR"/{skills,agents,agent-memory,hooks,rules,docs,templates/av-docs,registry}
mkdir -p "$CLAUDE_DIR/docs/av-claude-code-spec/topics"
mkdir -p "$CLAUDE_DIR/docs/av-ecosystem"

# 2. Skills (19개)
if [ -d "$SCRIPT_DIR/skills" ]; then
  cp -r "$SCRIPT_DIR/skills/." "$CLAUDE_DIR/skills/"
  echo "  ✓ Skills 설치 완료 ($(ls "$SCRIPT_DIR/skills" | wc -l)개)"
fi

# 3. Agents (9개)
if [ -d "$SCRIPT_DIR/agents" ]; then
  cp "$SCRIPT_DIR/agents/"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
  echo "  ✓ Agents 설치 완료 ($(ls "$SCRIPT_DIR/agents/"*.md 2>/dev/null | wc -l)개)"
fi

# 4. Agent memories (9개)
if [ -d "$SCRIPT_DIR/agent-memory" ]; then
  cp -r "$SCRIPT_DIR/agent-memory/." "$CLAUDE_DIR/agent-memory/"
  echo "  ✓ Agent memories 설치 완료"
fi

# 5. Hooks (5개 + 실행 권한)
if [ -d "$SCRIPT_DIR/hooks" ]; then
  cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
  chmod +x "$CLAUDE_DIR/hooks/"*.sh
  echo "  ✓ Hooks 설치 완료 ($(ls "$SCRIPT_DIR/hooks/"*.sh | wc -l)개)"
fi

# 6. Rules (3개)
if [ -d "$SCRIPT_DIR/rules" ]; then
  cp "$SCRIPT_DIR/rules/"*.md "$CLAUDE_DIR/rules/"
  echo "  ✓ Rules 설치 완료 ($(ls "$SCRIPT_DIR/rules/"*.md | wc -l)개)"
fi

# 7. Docs (topics 4개 + ecosystem + portable-guide)
if [ -d "$SCRIPT_DIR/docs" ]; then
  cp "$SCRIPT_DIR/docs/av-portable-guide.md" "$CLAUDE_DIR/docs/" 2>/dev/null || true
  cp "$SCRIPT_DIR/docs/av-claude-code-spec/topics/"*.md "$CLAUDE_DIR/docs/av-claude-code-spec/topics/" 2>/dev/null || true
  cp "$SCRIPT_DIR/docs/av-ecosystem/"*.md "$CLAUDE_DIR/docs/av-ecosystem/" 2>/dev/null || true
  echo "  ✓ Docs 설치 완료"
fi

# 8. Templates (16개)
if [ -d "$SCRIPT_DIR/templates/av-docs" ]; then
  cp "$SCRIPT_DIR/templates/av-docs/"*.tmpl "$CLAUDE_DIR/templates/av-docs/"
  echo "  ✓ Templates 설치 완료 ($(ls "$SCRIPT_DIR/templates/av-docs/"*.tmpl | wc -l)개)"
fi

# 9. Registry
cp "$SCRIPT_DIR/portable-components.json" "$CLAUDE_DIR/registry/components.json"
echo "  ✓ Registry 설치 완료"

# 10. sanitize-rules.json도 복사 (hydrate 참조용)
cp "$SCRIPT_DIR/sanitize-rules.json" "$CLAUDE_DIR/skills/av-vibe-forge/" 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════"
echo "  ✅ AutoVibe 생태계 설치 완료!"
echo "════════════════════════════════════════════"
echo ""
echo "다음 단계:"
echo "  1. Claude Code 재시작 (새 스킬 인식)"
echo "  2. /av-vibe-portable-init setup  ← 프로젝트 정보 입력 + Hydrate 자동 실행"
echo "  3. /av-vibe-forge health         ← 설치 검증"
echo ""
echo "문서: .claude/docs/av-portable-guide.md"
echo "════════════════════════════════════════════"

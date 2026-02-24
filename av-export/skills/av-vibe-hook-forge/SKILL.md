---
name: av-vibe-hook-forge
description: |
  AutoVibe 훅 생성기. Claude Code Hook 형식(JSON response, exit code) 준수
  셸 스크립트를 생성하고 .claude/settings.json에 자동 등록.
autovibe: true
version: "1.1"
created: "2026-02-21"
updated: "2026-02-22"
group: vibe
tier: meta
inherits: null
argument-hint: "[type] [name] --group {group}"
user-invocable: false
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Task, Bash]
---

# av-vibe-hook-forge — Hook Generator

## 역할

`av-vibe-forge hook [type] [name]`에 의해 위임 호출되는 훅 생성기.
Claude Code Hook 3종(PreToolUse/PostToolUse/SessionStart)을 표준 셸 스크립트로 생성하고,
`.claude/settings.json`에 자동 등록한다.

## Hook 3종 타입 스펙

> 📌 공식 스펙: https://code.claude.com/docs/en/hooks

| 타입 | 실행 시점 | stdin 입력 | stdout 출력 | 용도 |
|------|---------|-----------|------------|------|
| `PreToolUse` | 도구 호출 직전 | `{tool_name, tool_input, ...}` | allow=`echo '{}'` / deny=`hookSpecificOutput` / warn=`{systemMessage}` | 위험 패턴 차단 |
| `PostToolUse` | 도구 호출 직후 | `{tool_name, tool_input, tool_response, ...}` | `{decision:"block", reason}` 또는 `{systemMessage}` 또는 `{}` | 로깅, 검증 |
| `SessionStart` | 세션 시작 시 | `{source, model, ...}` | `{hookSpecificOutput:{additionalContext}}` 또는 단순 텍스트 | 생태계 상태 주입 |

### 응답 형식 핵심 규칙

```
allow  → echo '{}' && exit 0  ← 반드시 JSON 출력 필수 (빈 stdout → hook error 유발)
deny   → hookSpecificOutput.permissionDecision = "deny"  [PreToolUse 전용]
block  → decision: "block"  [PostToolUse/Stop 등 사용]
warn   → systemMessage (universal top-level 필드, 모든 이벤트 공통)
경로   → "$CLAUDE_PROJECT_DIR"/.claude/hooks/... (절대경로 필수)
```

> ⚠️ `{"decision":"allow"}` 형식은 **Deprecated** — hook error 유발. 절대 사용 금지.
> ⚠️ **빈 stdout + exit 0** 조합도 "hook error" 유발 확인됨 (2026-02-22 실증).
>    공식 스펙은 "exit 0으로 충분"이라 하지만 실제로는 `echo '{}'` 출력이 필수.

## Arguments

| 인자 | 필수 | 설명 |
|------|:----:|------|
| `type` | ✅ | PreToolUse/PostToolUse/SessionStart |
| `name` | ✅ | 훅 이름 (av- 자동 삽입) |
| `--group` | ❌ | 그룹 (base 기본) |
| `--tools` | ❌ | 감시 대상 도구 목록 (PostToolUse/PreToolUse 전용) |

## 훅 파일 표준 구조

### PostToolUse 예시

```bash
#!/bin/bash
# name: av-{name}
# autovibe: true
# version: 1.0
# created: YYYY-MM-DD
# hook-type: PostToolUse
# trigger-tools: Write, Edit
# description: 파일 변경 로깅 + av- frontmatter 검증

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 변경 로그 기록
if [ -n "$FILE_PATH" ]; then
  mkdir -p .claude/work
  echo "$(date +%Y-%m-%dT%H:%M:%S) $TOOL_NAME $FILE_PATH" >> .claude/work/change-log.txt
fi

echo "{}"
exit 0
```

### PreToolUse 예시

```bash
#!/bin/bash
# name: av-{name}
# autovibe: true
# version: 1.0
# created: YYYY-MM-DD
# hook-type: PreToolUse
# trigger-tools: Write, Edit
# description: {설명}

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# .env 파일 Write 차단 (실수 방지)
if [[ "$FILE_PATH" =~ \.env$ ]]; then
  # deny: hookSpecificOutput 형식 필수 (공식 최신 스펙)
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":".env 파일 직접 수정 금지. .env.example 사용"}}'
  exit 0
fi

# allow: 반드시 '{}' 출력 후 exit 0
# ⚠️ 빈 stdout은 "hook error" 유발 확인됨 (2026-02-22 실증)
# ⚠️ {"decision":"allow"} 절대 사용 금지 (Deprecated)
echo '{}'
exit 0
```

### SessionStart 예시

```bash
#!/bin/bash
# 생태계 상태 주입
REGISTRY=".claude/registry/components.json"
if [ -f "$REGISTRY" ]; then
  AGENT_COUNT=$(jq '.agents | length' "$REGISTRY")
  SKILL_COUNT=$(jq '.skills | length' "$REGISTRY")
  echo "{\"systemMessage\": \"AutoVibe 생태계: 에이전트 ${AGENT_COUNT}개, 스킬 ${SKILL_COUNT}개 활성화\"}"
else
  echo '{"systemMessage": "AutoVibe registry 미초기화 — /av-vibe-forge health 실행 권장"}'
fi
exit 0
```

## 프로세스 (10단계)

```
STEP 1-2: 메모리 로드
STEP 3: Read av-claude-code-spec.md Hook 섹션
STEP 4: AskUserQuestion →
        - 훅 타입 (PreToolUse/PostToolUse/SessionStart)
        - 감시 대상 도구 목록
        - 핵심 동작 설명
        - settings.json 자동 등록 여부
STEP 5: Write .claude/hooks/av-{name}.sh
        (셔뱅 + 메타 주석 + jq 파싱 + 로직 + JSON 응답)
STEP 6: Bash chmod +x .claude/hooks/av-{name}.sh
STEP 7: (선택) Edit .claude/settings.json
        → command 경로는 반드시 "$CLAUDE_PROJECT_DIR"/.claude/hooks/av-{name}.sh 형식 사용
        → hooks 배열에 {"matcher": "{type}", "hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/av-{name}.sh"}]} 추가
STEP 8: Edit .claude/registry/components.json
        → hooks.{name} 등록
        → _meta.total.hooks +1
STEP 9: Bash "echo '{}' | .claude/hooks/av-{name}.sh"
        → dry-run 테스트 (JSON parse 확인)
STEP 10: 메모리 업데이트 + 감사 요청 (Level 3)
```

## 오류 처리

| 조건 | 처리 |
|------|------|
| jq 미설치 | Bash which jq → 없으면 경고 + jq 없이 구현 안내 |
| settings.json 미존재 | Write 신규 생성 후 등록 |
| dry-run 실패 | 생성 훅 파일 표시 + 디버그 안내 |

## 실행 프로토콜 참조

- Frontmatter(Hook): `.claude/docs/av-claude-code-spec/topics/frontmatter-spec.md`
- 감사 규칙: `.claude/docs/av-claude-code-spec/topics/audit-rules.md`

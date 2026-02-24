---
name: av-util-redis
description: "redis-cli 기반 Redis 조회/관리 스킬 - redis MCP (20+ 도구) 대체"
argument-hint: "[get|set|keys|info|hgetall|del|ttl|type|ping|dbsize] [key]"
user-invocable: true
allowed-tools: Bash
autovibe: true
version: "1.0"
created: "2026-02-24"
group: base
tier: null
inherits: null
---

# Redis Ops 스킬

> `redis-cli` CLI를 사용하여 Redis 데이터를 조회/관리합니다.
> **대체 대상**: redis MCP (20+ MCP 도구) → 이 스킬 1개

## 접속 정보

```bash
redis-cli -h localhost -p 6379
```

## 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `ping` | 연결 상태 확인 | `/redis-ops ping` |
| `keys [pattern]` | 키 목록 조회 | `/redis-ops keys "session:*"` |
| `get [key]` | 문자열 값 조회 | `/redis-ops get "session:abc123"` |
| `set [key] [value]` | 값 설정 | `/redis-ops set "test:key" "hello"` |
| `del [key]` | 키 삭제 | `/redis-ops del "test:key"` |
| `ttl [key]` | TTL 확인 (초) | `/redis-ops ttl "session:abc123"` |
| `type [key]` | 데이터 타입 확인 | `/redis-ops type "session:abc123"` |
| `hgetall [key]` | 해시 전체 조회 | `/redis-ops hgetall "user:profile:123"` |
| `info [section]` | 서버 정보 조회 | `/redis-ops info memory` |
| `dbsize` | 전체 키 수 | `/redis-ops dbsize` |

## 실행 패턴

### ping
```bash
redis-cli -h localhost -p 6379 PING
```

### keys — 키 목록
```bash
redis-cli -h localhost -p 6379 KEYS "{pattern}"
# 예: KEYS "session:*"
# 예: KEYS "cache:tenant:*"
```

### get — 값 조회
```bash
redis-cli -h localhost -p 6379 GET "{key}"
```

### set — 값 설정 (TTL 포함)
```bash
redis-cli -h localhost -p 6379 SET "{key}" "{value}" EX {seconds}
```

### hgetall — 해시 전체 조회
```bash
redis-cli -h localhost -p 6379 HGETALL "{key}"
```

### info — 서버 정보
```bash
redis-cli -h localhost -p 6379 INFO {section}
# section: server, clients, memory, stats, keyspace 등
```

### scan — 안전한 키 탐색 (대용량 시 KEYS 대체)
```bash
redis-cli -h localhost -p 6379 SCAN 0 MATCH "{pattern}" COUNT 100
```

## {{PROJECT_NAME}} 키 패턴

| 패턴 | 용도 |
|------|------|
| `session:{sessionId}` | 사용자 세션 |
| `cache:tenant:{{{MULTI_TENANT_FIELD}}}:*` | 테넌트별 캐시 |
| `cache:code:{codeType}` | 공통코드 캐시 |
| `rate:limit:{ip}:{endpoint}` | Rate Limiting |
| `lock:{resourceId}` | 분산 잠금 |
| `nats:dedup:{eventId}` | {{MESSAGING_SYSTEM}} 중복 방지 |

## 주의사항

- 프로덕션에서 `KEYS *` 사용 금지 → `SCAN` 사용
- `FLUSHDB/FLUSHALL` 절대 사용 금지 (세션 데이터 손실)
- 읽기 전용 작업 선호 (쓰기는 애플리케이션 통해 수행)

ARGUMENTS: [ping|keys|get|set|del|ttl|type|hgetall|info|dbsize] [key]

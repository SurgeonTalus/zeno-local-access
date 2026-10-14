#!/usr/bin/env bash
set -e

/Users/sondre/zeno-discover-ports.sh >/tmp/zeno-discover.out
SIDECAR_PORT=$(cat /Users/sondre/.zeno-sidecar-port 2>/dev/null || true)
if [ -z "$SIDECAR_PORT" ]; then
  echo "Could not discover sidecar port"; exit 1
fi

ZENO_PID=$(pgrep -f "Zeno Helper --type=utility --utility-sub-type=node.mojom.NodeService" | head -1)
if [ -z "$ZENO_PID" ]; then echo "Zeno not running"; exit 1; fi

kill -USR1 "$ZENO_PID" 2>/dev/null || true
sleep 2

/opt/homebrew/bin/node /Users/sondre/zeno-heapdump.js > /tmp/zeno-current.heapsnapshot 2>/tmp/zeno-refresh.err &
HPID=$!
WAIT=0
while kill -0 $HPID 2>/dev/null; do
  sleep 1; WAIT=$((WAIT+1))
  if [ $WAIT -gt 90 ]; then kill $HPID 2>/dev/null; echo "snapshot timed out"; exit 1; fi
done
if [ ! -s /tmp/zeno-current.heapsnapshot ]; then
  echo "failed to capture heap snapshot"; cat /tmp/zeno-refresh.err; exit 1
fi

for uid in $(grep -oE '"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"' /tmp/zeno-current.heapsnapshot | tr -d '"' | sort -u); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -m3 -u "opencode:$uid" "http://127.0.0.1:${SIDECAR_PORT}/global/health")
  if [ "$CODE" = "200" ]; then
    printf '%s' "$uid" > /Users/sondre/.zeno-sidecar-password
    echo "Updated sidecar password: $uid (port $SIDECAR_PORT)"
    exit 0
  fi
done
echo "Could not discover password"; exit 1

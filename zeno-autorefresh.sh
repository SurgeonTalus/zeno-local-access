#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${HOME}"
LAST=""

while true; do
  PID=$(pgrep -f "Zeno Helper --type=utility --utility-sub-type=node.mojom.NodeService" | head -1)

  if [ -n "$PID" ] && [ "$PID" != "$LAST" ]; then
    for i in $(seq 1 60); do
      "${DIR}/zeno-discover-ports.sh" >/dev/null 2>&1
      SP=$(cat "${HOME_DIR}/.zeno-sidecar-port" 2>/dev/null || true)
      if [ -n "$SP" ] && curl -s -m2 "http://127.0.0.1:${SP}/global/health" >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    "${DIR}/zeno-refresh-password.sh" >/tmp/zeno-refresh.out 2>&1 || true

    if ! pgrep -f "zeno-auth-proxy.py" >/dev/null 2>&1; then
      nohup python3 "${DIR}/zeno-auth-proxy.py" > /tmp/zeno-proxy.log 2>&1 &
    fi

    if ! pgrep -f "flashmoe-proxy.py" >/dev/null 2>&1; then
      nohup python3 "${DIR}/flashmoe-proxy.py" > /tmp/flashmoe-proxy.log 2>&1 &
    fi

    LAST="$PID"
  fi

  "${DIR}/zeno-discover-ports.sh" >/dev/null 2>&1 || true

  if [ -z "$PID" ]; then
    LAST=""
  fi

  sleep 5
done

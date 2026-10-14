#!/usr/bin/env bash
# Determine current Zeno-sidecar (OpenCode API) port and flashmoe (LLM) port.
LOG=$(ls -t /Users/sondre/Library/Application\ Support/ai.zeno.desktop/logs/*/main.log 2>/dev/null | head -1)
SIDECAR_PORT=""
if [ -n "$LOG" ] && [ -f "$LOG" ]; then
  SIDECAR_PORT=$(grep -o "sidecar connection started { url: 'http://127.0.0.1:[0-9]*' }" "$LOG" | tail -1 | grep -oE "[0-9]+" | tail -1)
fi
# fallback: any Zeno helper listening port except 9229
if [ -z "$SIDECAR_PORT" ]; then
  HPID=$(pgrep -f "Zeno Helper --type=utility --utility-sub-type=node.mojom.NodeService" | head -1)
  if [ -n "$HPID" ]; then
    SIDECAR_PORT=$(lsof -nP -p "$HPID" -iTCP -sTCP:LISTEN 2>/dev/null | awk '{print $9}' | grep -oE "127.0.0.1:[0-9]+" | cut -d: -f2 | grep -v '^9229$' | head -1)
  fi
fi
FM_PID=$(pgrep -f "flashmoe.server" 2>/dev/null | head -1)
if [ -n "$FM_PID" ]; then
  FLASHMOE_PORT=$(ps -p "$FM_PID" -o command= 2>/dev/null | grep -oE -- "--port [0-9]+" | head -1 | awk '{print $2}')
else
  FLASHMOE_PORT=""
fi

if [ -n "$SIDECAR_PORT" ]; then printf '%s' "$SIDECAR_PORT" > /Users/sondre/.zeno-sidecar-port; fi
if [ -n "$FLASHMOE_PORT" ]; then printf '%s' "$FLASHMOE_PORT" > /Users/sondre/.zeno-flashmoe-port; fi

echo "sidecar=$SIDECAR_PORT flashmoe=$FLASHMOE_PORT"

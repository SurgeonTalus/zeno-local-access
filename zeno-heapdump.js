const http = require("http");
const WebSocket = globalThis.WebSocket;

function getWsUrl(cb) {
  http.get("http://127.0.0.1:9229/json/list", (res) => {
    let raw = "";
    res.on("data", (c) => (raw += c));
    res.on("end", () => {
      const arr = JSON.parse(raw);
      cb(arr[0].webSocketDebuggerUrl);
    });
  }).on("error", (e) => { console.error("json error", e.message); process.exit(1); });
}

getWsUrl((wsUrl) => {
  const ws = new WebSocket(wsUrl);
  let snapshot = "";
  ws.onopen = () => {
    ws.send(JSON.stringify({ id: 1, method: "HeapProfiler.enable" }));
  };
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id === 1) {
      ws.send(JSON.stringify({ id: 2, method: "HeapProfiler.takeHeapSnapshot", params: { reportProgress: false } }));
    }
    if (msg.method === "HeapProfiler.addHeapSnapshotChunk") {
      snapshot += msg.params.chunk;
    }
    if (msg.id === 2) {
      process.stdout.write(snapshot);
      process.exit(0);
    }
  };
  ws.onerror = (e) => { console.error("ws error", e.message || e); process.exit(1); };
  setTimeout(() => { console.error("timeout"); process.exit(1); }, 120000);
});

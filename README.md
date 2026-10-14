# Zeno Local Access

Scripts to access the OpenCode server embedded inside the Zeno macOS app.

Zeno (v1.0.11) starts a protected `opencode` sidecar on a random localhost port with a per-session UUID password, and exposes Qwen 3.6 through a flashmoe server on another random port. These scripts:

- discover the current ports;
- enable the Node inspector in Zeno's main process and extract the sidecar password from its heap;
- run a no-login proxy on `127.0.0.1:4098` for the sidecar;
- run a proxy on `127.0.0.1:63457` that tracks Zeno's flashmoe port, so GenOffice can use the stable URL `http://127.0.0.1:63457/v1`;
- auto-refresh on Zeno launch via a LaunchAgent.

## Usage

- GenOffice / OpenAI-compatible client: base URL `http://127.0.0.1:63457/v1`, model `mlx-community/Qwen3.6-35B-A3B-4bit`.
- Zeno native sidecar: `http://127.0.0.1:<port>` with user `opencode` and the password in `~/.zeno-sidecar-password`.
- No-password sidecar access: `http://127.0.0.1:4098`.

## Files

- `zeno-discover-ports.sh`
- `zeno-refresh-password.sh`
- `zeno-autorefresh.sh`
- `zeno-heapdump.js`
- `zeno-auth-proxy.py`
- `flashmoe-proxy.py`
- `com.zeno.local-autorefresh.plist`

## Notes

- macOS only, requires the Zeno app installed.
- Password extraction requires sending `SIGUSR1` to Zeno's helper utility process and a heap snapshot; no Zeno code is modified.

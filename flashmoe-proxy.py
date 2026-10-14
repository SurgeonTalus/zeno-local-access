import os
import http.server, socketserver, urllib.request, os

PORT_FILE = os.path.expanduser("~/.zeno-flashmoe-port")
UPSTREAM_HOST = "127.0.0.1"
FIXED_FALLBACK = "63457"

def get_upstream():
    try:
        port = open(PORT_FILE).read().strip()
    except Exception:
        port = ""
    if not port:
        port = FIXED_FALLBACK
    return f"http://{UPSTREAM_HOST}:{port}"

class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _forward(self):
        upstream = get_upstream()
        length = int(self.headers.get("Content-Length", 0) or 0)
        body = self.rfile.read(length) if length else b""
        url = upstream + self.path
        req = urllib.request.Request(url, data=body if body else None, method=self.command)
        for k, v in self.headers.items():
            if k.lower() not in ("host", "authorization", "content-length"):
                req.add_header(k, v)
        if body:
            req.add_header("Content-Length", str(len(body)))
        try:
            with urllib.request.urlopen(req) as resp:
                self.send_response(resp.status)
                for k, v in resp.getheaders():
                    if k.lower() in ("transfer-encoding", "connection", "keep-alive"):
                        continue
                    self.send_header(k, v)
                self.send_header("Connection", "keep-alive")
                self.end_headers()
                while True:
                    chunk = resp.read(4096)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for k, v in e.headers.items():
                if k.lower() not in ("transfer-encoding", "connection"):
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            try:
                self.send_error(502, str(e))
            except Exception:
                pass

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = do_OPTIONS = do_HEAD = _forward

    def log_message(self, *a):
        pass

socketserver.ThreadingTCPServer.allow_reuse_address = True
with socketserver.ThreadingTCPServer(("127.0.0.1", 63457), Handler) as httpd:
    httpd.serve_forever()

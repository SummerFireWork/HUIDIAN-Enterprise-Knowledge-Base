#!/usr/bin/env python3
"""BGE-M3 mock 服务（仅本地链路演示，无真实模型）：
GET  /info    -> {"model": "BAAI/bge-m3", "dims": 1024, "mock": true}
POST /embed   -> {"embeddings": [[1024 floats]...], "model": "BAAI/bge-m3", "dims": 1024}
确定性伪向量：文本哈希为种子 + 位置正弦分量，L2 归一化；同一文本向量恒定（检索可命中）。
"""
import hashlib
import json
import math
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DIMS = 1024
MODEL = "BAAI/bge-m3"


def pseudo_vector(text: str) -> list:
    seed = int(hashlib.md5(text.encode("utf-8")).hexdigest()[:8], 16)
    vec = [math.sin((seed % 1000) * 0.01 + i * 0.001) for i in range(DIMS)]
    norm = math.sqrt(sum(v * v for v in vec))
    return [v / norm for v in vec]


class Handler(BaseHTTPRequestHandler):
    def _send(self, obj, status=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/info":
            self._send({"model": MODEL, "dims": DIMS, "mock": True})
        else:
            self._send({"error": "not found"}, 404)

    def do_POST(self):
        if self.path != "/embed":
            self._send({"error": "not found"}, 404)
            return
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length)
        try:
            req = json.loads(raw)
            texts = req.get("texts") or []
        except Exception:
            self._send({"error": "bad json"}, 400)
            return
        embeddings = [pseudo_vector(t) for t in texts]
        self._send({"embeddings": embeddings, "model": MODEL, "dims": DIMS})

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()

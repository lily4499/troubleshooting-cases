from http.server import BaseHTTPRequestHandler, HTTPServer
import os

PORT = int(os.getenv("MYAPI_PORT", "3000"))
MESSAGE = os.getenv("MYAPI_MESSAGE", "myapi is running")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/health"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write((f'{{"status":"ok","service":"myapi","message":"{MESSAGE}"}}').encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        return

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"myapi listening on port {PORT}")
    server.serve_forever()

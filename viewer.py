#!/usr/bin/env python3
import http.server
import socketserver
import os
import json
import mimetypes

PORT = 8080
REPO_DIR = "/home/mint/firetv-clean-root"

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>mint/firetv-clean-root: True Native Launcher Replacement & Debloat Toolkit for Fire TV</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.5.1/github-markdown-dark.min.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
  <style>
    :root {
      --bg: #0d1117;
      --card-bg: #161b22;
      --border: #30363d;
      --text: #e6edf3;
      --muted: #848d97;
      --blue: #2f81f7;
      --green: #238636;
      --btn-bg: #21262d;
      --btn-hover: #30363d;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
      font-size: 14px;
      line-height: 1.5;
    }
    header {
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
      padding: 16px 32px;
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .gh-logo { fill: #fff; width: 32px; height: 32px; }
    .repo-title { font-size: 18px; font-weight: 600; }
    .repo-title a { color: var(--blue); text-decoration: none; }
    .badge {
      display: inline-block;
      padding: 2px 8px;
      font-size: 12px;
      font-weight: 500;
      border-radius: 2em;
      border: 1px solid var(--border);
      color: var(--muted);
    }
    .tabs {
      display: flex;
      gap: 20px;
      padding: 0 32px;
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
    }
    .tab {
      padding: 12px 4px;
      cursor: pointer;
      color: var(--text);
      border-bottom: 2px solid transparent;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .tab.active {
      border-bottom-color: #f78166;
    }
    .container {
      max-width: 1280px;
      margin: 24px auto;
      padding: 0 24px;
      display: grid;
      grid-template-columns: 280px 1fr;
      gap: 24px;
    }
    .sidebar {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 16px;
      height: fit-content;
    }
    .sidebar h3 {
      margin: 0 0 12px;
      font-size: 14px;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .tree-item {
      padding: 6px 8px;
      border-radius: 4px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--text);
      text-decoration: none;
      word-break: break-all;
    }
    .tree-item:hover, .tree-item.active {
      background: rgba(177, 186, 196, 0.12);
      color: var(--blue);
    }
    .tree-folder { font-weight: 600; color: #7ee787; }
    .content-area {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 6px;
      overflow: hidden;
    }
    .content-header {
      padding: 12px 16px;
      background: #161b22;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .breadcrumb {
      font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
      font-size: 13px;
    }
    .content-body {
      padding: 24px 32px;
      background: #0d1117;
      min-height: 400px;
    }
    pre { margin: 0; background: transparent; }
    code { font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; font-size: 13px; }
    .actions-bar {
      display: flex;
      gap: 8px;
    }
    .btn {
      background: var(--btn-bg);
      color: var(--text);
      border: 1px solid var(--border);
      padding: 5px 12px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 500;
      text-decoration: none;
    }
    .btn:hover { background: var(--btn-hover); }
    .btn-primary { background: var(--green); color: #fff; border-color: rgba(240,246,252,0.1); }
  </style>
</head>
<body>
  <header>
    <svg class="gh-logo" viewBox="0 0 16 16"><path d="M8 0c4.42 0 8 3.58 8 8a8.013 8.013 0 0 1-5.45 7.59c-.4.08-.55-.17-.55-.38 0-.27.01-1.13.01-2.2 0-.75-.25-1.23-.54-1.48 1.78-.2 3.65-.88 3.65-3.95 0-.88-.31-1.59-.82-2.15.08-.2.36-1.02-.08-2.12 0 0-.67-.22-2.2.82-.64-.18-1.32-.27-2-.27-.68 0-1.36.09-2 .27-1.53-1.03-2.2-.82-2.2-.82-.44 1.1-.16 1.92-.08 2.12-.51.56-.82 1.28-.82 2.15 0 3.06 1.86 3.75 3.64 3.95-.23.2-.44.55-.51 1.07-.46.21-1.61.55-2.33-.66-.15-.24-.6-.83-1.23-.82-.67.01-.27.38.01.53.34.19.73.9.82 1.13.16.45.68 1.31 2.69.94 0 .67.01 1.3.01 1.49 0 .21-.15.45-.55.38A7.995 7.995 0 0 1 0 8c0-4.42 3.58-8 8-8Z"></path></svg>
    <div class="repo-title">
      <a href="#">mint</a> / <a href="#">firetv-clean-root</a>
      <span class="badge">Public</span>
    </div>
  </header>

  <div class="tabs">
    <div class="tab active" onclick="loadTab('code')">Code</div>
    <div class="tab" onclick="loadTab('docs')">Documentation</div>
    <div class="tab" onclick="loadTab('scripts')">Scripts</div>
    <div class="tab" onclick="loadTab('releases')">Releases <span class="badge" style="margin-left:4px;">1</span></div>
  </div>

  <div class="container">
    <div class="sidebar">
      <h3>Repository Files</h3>
      <div id="file-tree"></div>
    </div>

    <div class="content-area">
      <div class="content-header">
        <div class="breadcrumb" id="current-filename">README.md</div>
        <div class="actions-bar">
          <a class="btn" id="raw-btn" target="_blank">Raw</a>
          <button class="btn btn-primary" onclick="copyPath()">Copy Path</button>
        </div>
      </div>
      <div class="content-body">
        <div id="markdown-view" class="markdown-body"></div>
        <pre><code id="code-view"></code></pre>
      </div>
    </div>
  </div>

  <script>
    let currentPath = "README.md";

    async function fetchTree() {
      const res = await fetch("/api/tree");
      const files = await res.json();
      const treeEl = document.getElementById("file-tree");
      treeEl.innerHTML = "";
      
      files.forEach(f => {
        const item = document.createElement("div");
        item.className = "tree-item" + (f === currentPath ? " active" : "");
        const icon = f.endsWith(".md") ? "" : (f.endsWith(".sh") ? "" : (f.endsWith(".apk") ? "" : ""));
        item.innerHTML = `<span>${icon}</span> <span>${f}</span>`;
        item.onclick = () => loadFile(f);
        treeEl.appendChild(item);
      });
    }

    async function loadFile(filePath) {
      currentPath = filePath;
      document.getElementById("current-filename").innerText = filePath;
      document.getElementById("raw-btn").href = "/raw/" + filePath;

      document.querySelectorAll(".tree-item").forEach(el => {
        el.classList.toggle("active", el.innerText.includes(filePath));
      });

      const res = await fetch("/api/file?path=" + encodeURIComponent(filePath));
      const data = await res.json();

      const mdView = document.getElementById("markdown-view");
      const codeView = document.getElementById("code-view");

      if (filePath.endsWith(".md")) {
        codeView.parentElement.style.display = "none";
        mdView.style.display = "block";
        mdView.innerHTML = marked.parse(data.content);
        mdView.querySelectorAll("pre code").forEach(el => hljs.highlightElement(el));
      } else {
        mdView.style.display = "none";
        codeView.parentElement.style.display = "block";
        codeView.innerText = data.content;
        codeView.className = "";
        hljs.highlightElement(codeView);
      }
    }

    function loadTab(tab) {
      document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
      event.target.classList.add("active");
      if (tab === "code") loadFile("README.md");
      else if (tab === "docs") loadFile("docs/ARCHITECTURE.md");
      else if (tab === "scripts") loadFile("scripts/04_install_launcher.sh");
      else if (tab === "releases") loadFile("docs/TROUBLESHOOTING.md");
    }

    function copyPath() {
      navigator.clipboard.writeText("/home/mint/firetv-clean-root/" + currentPath);
      alert("Copied path to clipboard: /home/mint/firetv-clean-root/" + currentPath);
    }

    fetchTree().then(() => loadFile("README.md"));
  </script>
</body>
</html>
"""

class RepoHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
        elif self.path == "/api/tree":
            file_list = []
            for root, dirs, files in os.walk(REPO_DIR):
                if ".git" in root:
                    continue
                for f in sorted(files):
                    rel = os.path.relpath(os.path.join(root, f), REPO_DIR)
                    file_list.append(rel)
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(sorted(file_list)).encode("utf-8"))
        elif self.path.startswith("/api/file?path="):
            from urllib.parse import parse_qs, urlparse
            query = parse_qs(urlparse(self.path).query)
            target = query.get("path", ["README.md"])[0]
            full_path = os.path.join(REPO_DIR, target)
            if os.path.exists(full_path) and os.path.isfile(full_path):
                try:
                    with open(full_path, "r", encoding="utf-8", errors="replace") as f:
                        content = f.read()
                except Exception as e:
                    content = f"Error reading file: {e}"
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"path": target, "content": content}).encode("utf-8"))
            else:
                self.send_response(404)
                self.end_headers()
        elif self.path.startswith("/raw/"):
            target = self.path[5:]
            full_path = os.path.join(REPO_DIR, target)
            if os.path.exists(full_path) and os.path.isfile(full_path):
                self.send_response(200)
                mime, _ = mimetypes.guess_type(full_path)
                self.send_header("Content-type", mime or "text/plain")
                self.end_headers()
                with open(full_path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), RepoHandler) as httpd:
        print(f"Serving repository web viewer on http://localhost:{PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass

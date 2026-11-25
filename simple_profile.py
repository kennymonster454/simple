# SIMPLE PYTHON PROFILE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 3.7.0
#
# Python port of Microsoft.PowerShell_profile.ps1.
# Keeps the same SIMPLE command language while adapting Windows-only features
# so the profile can also run on Android, Linux, and macOS.
#
# Run directly: python simple_profile.py <command>
# In Python interactive mode: import simple_profile; simple_profile.simple("help")

from __future__ import annotations

import base64
import datetime as _dt
import html
import json
import os
import platform
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

VERSION = "3.7.0"
REPOSITORY = "kennymonster454/simple"
PYTHON_FILE = "simple_profile.py"
API_FILE_URL = f"https://api.github.com/repos/{REPOSITORY}/contents/{PYTHON_FILE}?ref=main"
RAW_FILE_URL = f"https://raw.githubusercontent.com/{REPOSITORY}/main/{PYTHON_FILE}"
OFFLINE = False
VECTOR_IP = None
SERVERS = {}


def _print(text=""):
    print(text)


def _request(url, timeout=20, headers=None):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "SIMPLE-Python-Updater", **(headers or {})},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def _normalise_args(args):
    fixes = {
        "shwo": "show", "sho": "show", "opn": "open", "opne": "open",
        "flies": "files", "fiels": "files", "drivs": "drives",
        "foldrs": "folders", "folers": "folders", "progams": "programs",
        "calclator": "calculator", "calculater": "calculator",
        "notpad": "notepad", "creat": "create", "foler": "folder",
        "tim": "time", "comand": "command", "comands": "commands",
    }
    args = list(args)
    if args and args[0].lower() != "say":
        for index in (0, 1, 2):
            if index >= len(args):
                break
            if index == 1 and args[0].lower() not in ("show", "open", "go", "create"):
                break
            if index == 2 and not (
                (args[0].lower(), args[1].lower()) in (("show", "my"), ("create", "a"))
            ):
                break
            old = args[index].lower()
            if old in fixes:
                args[index] = fixes[old]
                _print(f"SIMPLE spelling fix: {old} -> {args[index]}")
    return args


def _open_target(target):
    target = target.strip().strip('"')
    parsed = urllib.parse.urlparse(target)
    if parsed.scheme in ("http", "https"):
        if parsed.hostname not in ("localhost", "127.0.0.1", "::1"):
            _print("SIMPLE windows only open local files or localhost addresses.")
            return
        webbrowser.open(target)
        return
    path = Path(target).expanduser()
    if not path.is_file():
        _print(f"HTML file not found: {target}")
        return
    if path.suffix.lower() not in (".html", ".htm"):
        _print("Please select an .html or .htm file.")
        return
    webbrowser.open(path.resolve().as_uri())


def _default_html():
    return """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIMPLE</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#071b12;color:#eaffef;
font-family:Arial,sans-serif;line-height:1.55}
.top{background:linear-gradient(135deg,#087a3d,#16a34a);padding:34px 26px;
border-bottom:4px solid #5ee58b}.wrap{max-width:980px;margin:auto;padding:26px 22px}
.brand{font-size:38px;font-weight:800;letter-spacing:2px;margin:0;color:white}
.tag{margin:5px 0 0;color:#d8ffe4}.panel{background:#102b1d;border:1px solid #236b43;
border-radius:12px;padding:20px;margin-bottom:20px}h2{color:#86efac}
.grid{display:flex;flex-wrap:wrap;gap:12px}.item{flex:1 1 260px;background:#0a2116;
border:1px solid #205b39;border-radius:9px;padding:13px}
code{color:#a7f3c0;background:#153c27;padding:3px 6px;border-radius:5px}
p{color:#d5eadd}.foot{color:#8db69a;text-align:center;font-size:13px}
</style></head><body>
<header class="top"><div class="wrap"><h1 class="brand">SIMPLE</h1>
<p class="tag">Your local SIMPLE command center</p></div></header>
<main class="wrap"><section class="panel"><h2>Welcome</h2>
<p>SIMPLE is a small command language created by Kenny. This page is stored locally.</p>
<p><strong style="color:#86efac">Local page: ready</strong></p></section>
<section class="panel"><h2>Commands</h2><div class="grid">
<div class="item"><code>simple print &lt;text&gt;</code><p>Prints text.</p></div>
<div class="item"><code>simple vector ip &lt;address&gt;</code><p>Stores Vector's IP address.</p></div>
<div class="item"><code>simple open window &lt;HTML path&gt;</code><p>Opens a local HTML page.</p></div>
<div class="item"><code>simple localhost start &lt;port&gt;</code><p>Starts a local web server.</p></div>
<div class="item"><code>simple offline</code><p>Turns on offline mode.</p></div>
<div class="item"><code>simple online</code><p>Turns online mode back on.</p></div>
<div class="item"><code>simple update</code><p>Checks GitHub for Python profile updates.</p></div>
</div></section><section class="panel"><h2>Updates</h2>
<p>Use <code>simple update timeline</code> to view Python profile history.</p></section>
<div class="foot">SIMPLE • Local command center</div></main></body></html>"""


def _make_game(description, requested_mode=""):
    desc = description.strip()
    mode = "2.5D" if (
        requested_mode.lower() == "2.5d"
        or re.search(r"2\.5d|3d-looking|almost fully 3d", desc, re.I)
    ) else "2D"
    title = "SPE Adventure"
    for pattern, name in (
        (r"cat|kitten", "Cat Adventure"),
        (r"robot", "Robot Adventure"),
        (r"space|spaceship|planet|astronaut", "Space Adventure"),
        (r"haunted|ghost", "Haunted Adventure"),
        (r"dinosaur|dino", "Dinosaur Adventure"),
        (r"forest|woods", "Forest Adventure"),
    ):
        if re.search(pattern, desc, re.I):
            title = name
            break

    title_json = json.dumps(title)
    mode_json = json.dumps(mode)
    game_html = r"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SPE Game</title><style>
html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#101827;color:white;
font-family:Arial}canvas{display:block;width:100%;height:100%}
#hud{position:fixed;top:14px;left:14px;padding:12px 16px;background:#101827dd;
border:1px solid #ffffff55;border-radius:10px}
#help{position:fixed;bottom:14px;left:50%;transform:translateX(-50%);
padding:9px 14px;background:#101827dd;border-radius:8px}
#win{display:none;position:fixed;inset:0;align-items:center;justify-content:center;
background:#07101dcc;font-size:36px;font-weight:bold}
</style></head><body><canvas id="game"></canvas>
<div id="hud"><b id="title"></b><div id="mode"></div><div id="score">Stars: 0/8</div></div>
<div id="help">Move: WASD / arrows · Collect 8 stars</div><div id="win">YOU WIN!</div>
<script>
const TITLE=__TITLE__,MODE=__MODE__;document.title=TITLE+" - SPE";
document.getElementById("title").textContent=TITLE;
document.getElementById("mode").textContent=MODE+" game";
const c=document.getElementById("game"),g=c.getContext("2d");
let w=0,h=0,keys={},score=0,won=false;const p={x:100,y:100};let stars=[];
function size(){w=c.width=innerWidth;h=c.height=innerHeight}addEventListener("resize",size);size();
function reset(){score=0;won=false;p.x=w/2;p.y=h/2;stars=[];
for(let i=0;i<8;i++)stars.push({x:30+Math.random()*Math.max(1,w-60),
y:60+Math.random()*Math.max(1,h-100),got:false})}
addEventListener("keydown",e=>{keys[e.key.toLowerCase()]=true;
if(e.key.startsWith("Arrow"))e.preventDefault()});
addEventListener("keyup",e=>keys[e.key.toLowerCase()]=false);
function circle(x,y,r,color){g.beginPath();g.arc(x,y,r,0,Math.PI*2);g.fillStyle=color;g.fill()}
function frame(){g.fillStyle=MODE==="2.5D"?"#24434d":"#183b2b";g.fillRect(0,0,w,h);
g.strokeStyle="#ffffff18";for(let x=0;x<w;x+=50){g.beginPath();g.moveTo(x,0);g.lineTo(x,h);g.stroke()}
for(let y=0;y<h;y+=50){g.beginPath();g.moveTo(0,y);g.lineTo(w,y);g.stroke()}
if(!won){let dx=(keys.d||keys.arrowright?1:0)-(keys.a||keys.arrowleft?1:0);
let dy=(keys.s||keys.arrowdown?1:0)-(keys.w||keys.arrowup?1:0),m=Math.hypot(dx,dy)||1;
p.x=Math.max(12,Math.min(w-12,p.x+dx/m*3));
p.y=Math.max(12,Math.min(h-12,p.y+dy/m*3));
stars.forEach(s=>{if(!s.got&&Math.hypot(s.x-p.x,s.y-p.y)<20){s.got=true;score++;
document.getElementById("score").textContent="Stars: "+score+"/8";
if(score===8){won=true;document.getElementById("win").style.display="flex"}}})}
stars.forEach(s=>{if(!s.got)circle(s.x,s.y,8,"#ffe58a")});
circle(p.x,p.y+4,14,"#0008");circle(p.x,p.y,12,"#54d9e8");
circle(p.x,p.y-3,5,"#e5fbff");requestAnimationFrame(frame)}
reset();requestAnimationFrame(frame);
</script></body></html>"""
    game_html = game_html.replace("__TITLE__", title_json).replace("__MODE__", mode_json)
    safe_title = re.sub(r'[\\/:*?"<>|]', "", title).strip() or "SPE Adventure"
    output = Path.cwd() / f"{safe_title}.spe"
    number = 2
    while output.exists():
        output = Path.cwd() / f"{safe_title}-{number}.spe"
        number += 1
    game = {
        "format": "SPE", "formatVersion": 1, "title": title,
        "mode": mode, "description": desc, "html": game_html,
    }
    output.write_text(json.dumps(game, ensure_ascii=False, indent=2), encoding="utf-8")
    _print("SPE game created!")
    _print(f"Title: {title}\nMode: {mode}\nFile: {output}")
    _print(f'Run it with: simple run "{output}"')


def _run_file(path_text):
    path = Path(path_text.strip().strip('"')).expanduser()
    if not path.is_file():
        _print(f"File not found: {path}")
        return
    suffix = path.suffix.lower()
    try:
        if suffix == ".smp":
            for line in path.read_text(encoding="utf-8-sig").splitlines():
                command = line.strip()
                if command and not command.startswith("#"):
                    _print("> " + command)
                    simple(command)
        elif suffix == ".spe":
            game = json.loads(path.read_text(encoding="utf-8"))
            if game.get("format") != "SPE" or not isinstance(game.get("html"), str) or not game["html"].strip():
                raise ValueError("Invalid SPE file.")
            folder = Path(tempfile.gettempdir()) / "SIMPLE-SPE"
            folder.mkdir(parents=True, exist_ok=True)
            html_path = folder / (path.stem + ".html")
            html_path.write_text(game["html"], encoding="utf-8")
            _print("Launching SPE game: " + str(game.get("title", path.stem)))
            webbrowser.open(html_path.resolve().as_uri())
        else:
            _print("SIMPLE runs .smp scripts and .spe games.")
    except Exception as exc:
        _print(f"Could not run file: {exc}")


def _update_timeline():
    _print("Loading SIMPLE version timeline...")
    try:
        url = f"https://api.github.com/repos/{REPOSITORY}/commits?path={PYTHON_FILE}&per_page=100"
        history = json.loads(_request(url).decode("utf-8"))
        choices = []
        for entry in history:
            commit = entry.get("commit", {})
            sha = entry.get("sha")
            if not sha:
                continue
            message = (commit.get("message") or "").splitlines()[0]
            date_text = commit.get("author", {}).get("date", "")
            try:
                date = _dt.datetime.fromisoformat(date_text.replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d %H:%M")
            except Exception:
                date = date_text
            choices.append((sha, date, message))
        if not choices:
            raise RuntimeError("GitHub returned no Python profile history.")
        _print("\nSIMPLE PYTHON VERSION TIMELINE")
        for i, (_, date, message) in enumerate(choices, 1):
            _print(f"[{i}] {date} | {choices[i-1][0][:7]} | {message}")
        _print("[0] Cancel")
        selection = input("Choose a version: ").strip()
        if selection in ("", "0"):
            _print("Cancelled.")
            return
        if not selection.isdigit() or not 1 <= int(selection) <= len(choices):
            _print("That is not a valid timeline number.")
            return
        sha = choices[int(selection)-1][0]
        historical_url = f"https://raw.githubusercontent.com/{REPOSITORY}/{sha}/{PYTHON_FILE}"
        historical = _request(historical_url).decode("utf-8")
        compile(historical, PYTHON_FILE, "exec")
        if not re.search(r"(?m)^# VERSION \S+", historical) or "def simple(" not in historical:
            raise RuntimeError("That commit is not a SIMPLE Python profile.")
        target = Path(__file__).resolve()
        backup = target.with_name(target.name + ".timeline-backup")
        shutil.copy2(target, backup)
        temp = target.with_name(target.name + ".timeline-tmp")
        temp.write_text(historical, encoding="utf-8")
        os.replace(temp, target)
        _print(f"Restored SIMPLE version {sha[:7]}.")
        _print(f"Backup: {backup}")
        _print("Use 'simple update' to return to the latest Python version.")
    except Exception as exc:
        _print(f"Timeline failed: {exc}")


def _update():
    global VERSION
    if OFFLINE:
        _print("SIMPLE is OFFLINE. The update command is unavailable in offline mode.")
        _print("Connect to the internet, then type: simple online")
        return
    _print("Checking for Simple updates...")
    target = Path(__file__).resolve()
    temp = target.with_name(target.name + ".simple-update.tmp")
    try:
        payload = json.loads(_request(API_FILE_URL, headers={"Accept": "application/vnd.github+json", "Cache-Control": "no-cache"}).decode("utf-8"))
        if payload.get("encoding") != "base64" or not payload.get("content"):
            raise RuntimeError("GitHub did not return the Python profile as base64 content.")
        new_code = base64.b64decode("".join(payload["content"].split())).decode("utf-8")
        if not new_code.strip() or not re.search(r"(?m)^# VERSION \S+", new_code) or "def simple(" not in new_code:
            raise RuntimeError("The downloaded file is not a valid SIMPLE Python profile.")
        compile(new_code, PYTHON_FILE, "exec")
        match = re.search(r"(?m)^# VERSION (.+?)\s*$", new_code)
        online_version = match.group(1).strip() if match else "unknown"
        installed_code = target.read_text(encoding="utf-8")
        installed_match = re.search(r"(?m)^# VERSION (.+?)\\s*$", installed_code)
        installed_version = installed_match.group(1).strip() if installed_match else VERSION
        if installed_code.replace("\\r\\n", "\\n").rstrip() == new_code.replace("\\r\\n", "\\n").rstrip():
            _print(f"Simple {installed_version} is already up to date.")
            return
        temp.write_text(new_code, encoding="utf-8")
        verify = temp.read_text(encoding="utf-8")
        compile(verify, str(temp), "exec")
        if verify.replace("\\r\\n", "\\n").rstrip() != new_code.replace("\\r\\n", "\\n").rstrip():
            raise RuntimeError("The temporary update file did not pass verification.")
        backup = target.with_name(target.name + ".backup")
        shutil.copy2(target, backup)
        os.replace(temp, target)
        _print(f"Simple updated from {installed_version} to {online_version}!")
        _print(f"Backup: {backup}")
        _print("Restart SIMPLE to load the updated Python profile.")
    except Exception as exc:
        _print(f"Update failed: {exc}")
        _print("Your previous profile was kept.")
    finally:
        try:
            temp.unlink(missing_ok=True)
        except Exception:
            pass


def _show_drives():
    if os.name == "nt":
        roots = [Path(f"{letter}:/") for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    else:
        roots = [Path("/")]
        for base in (Path("/storage"), Path("/mnt")):
            if base.exists():
                roots.extend(p for p in base.iterdir() if p.is_dir())
    seen = set()
    for root in roots:
        try:
            resolved = str(root.resolve())
            if resolved in seen or not root.exists():
                continue
            seen.add(resolved)
            usage = shutil.disk_usage(root)
            _print(f"{root}  Total: {usage.total:,}  Used: {usage.used:,}  Free: {usage.free:,}")
        except (OSError, PermissionError):
            continue


def _list_files(folder, folders_only=False):
    try:
        entries = sorted(folder.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))
        for item in entries:
            if folders_only and not item.is_dir():
                continue
            kind = "DIR " if item.is_dir() else "FILE"
            size = "" if item.is_dir() else f"{item.stat().st_size:,} bytes"
            _print(f"{kind:4} {size:>14}  {item.name}")
    except Exception as exc:
        _print(f"Could not list files: {exc}")


def _open_path(path):
    try:
        path = Path(path).expanduser()
        if not path.exists():
            _print(f"Location unavailable: {path}")
            return
        if os.name == "nt":
            os.startfile(str(path))
        elif sys.platform == "darwin":
            subprocess.Popen(["open", str(path)])
        else:
            subprocess.Popen(["xdg-open", str(path)])
    except Exception as exc:
        _print(f"Could not open location: {exc}")


def _localhost(args):
    global SERVERS
    if len(args) < 3:
        _print("Usage: simple localhost start/stop/status <port>")
        return
    action = args[1].lower()
    try:
        port = int(args[2])
        if not 1 <= port <= 65535:
            raise ValueError
    except ValueError:
        _print("Invalid port.")
        return
    if action == "start":
        _print("\nDo you want to add an HTML file or keep the default?")
        _print("Type 1 for HTML")
        _print("Type 2 for default")
        choice = input("SIMPLE: ").strip()
        if choice == "1":
            raw = input("HTML file path: ").strip().strip('"')
            html_path = Path(raw).expanduser()
            if not html_path.is_file() or html_path.suffix.lower() not in (".html", ".htm"):
                _print("HTML file not found or not an HTML file.")
                return
            folder = html_path.resolve().parent
        elif choice == "2":
            folder = Path.home() / ".simple" / "Localhost"
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "index.html").write_text(_default_html(), encoding="utf-8")
        else:
            _print("Invalid choice.")
            return
        if port in SERVERS:
            _print(f"SIMPLE localhost is already running on port {port}.")
            return
        try:
            from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
            import functools
            handler = functools.partial(SimpleHTTPRequestHandler, directory=str(folder))
            server = ThreadingHTTPServer(("127.0.0.1", port), handler)
            import threading
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            SERVERS[port] = (server, thread, folder)
            _print("Simple localhost started!")
            _print(f"Port: {port}")
            _print(f"Address: http://localhost:{port}")
            _print(f"Folder: {folder}")
        except Exception as exc:
            _print(f"Could not start localhost: {exc}")
    elif action == "stop":
        if port not in SERVERS:
            _print(f"No SIMPLE localhost server is running on port {port}.")
            return
        server, thread, _ = SERVERS.pop(port)
        server.shutdown()
        server.server_close()
        _print(f"SIMPLE localhost stopped on port {port}.")
    elif action == "status":
        if port in SERVERS:
            _print(f"SIMPLE localhost is running: http://localhost:{port}")
        else:
            _print(f"SIMPLE localhost is not running on port {port}.")
    else:
        _print("Unknown localhost command.")


def simple(*raw_args):
    global OFFLINE, VECTOR_IP
    if len(raw_args) == 1 and isinstance(raw_args[0], str):
        args = raw_args[0].strip().split()
    else:
        args = [str(a) for a in raw_args]
    args = _normalise_args(args)
    english = " ".join(args).strip()

    if english.lower() == "offline":
        OFFLINE = True
        _print("SIMPLE is now OFFLINE.")
        _print("Local commands remain available. Updates are disabled until you type: simple online")
        return
    if english.lower() == "online":
        OFFLINE = False
        _print("SIMPLE is now ONLINE.")
        _print("All commands are available, including: simple update")
        return

    if len(args) >= 2 and args[0].lower() == "run":
        _run_file(" ".join(args[1:]))
        return

    game_match = re.match(r"make (?:me )?(?:a )?(?:(2\.5d|2d)\s+)?game(?:\s+where)?\s+(.+)", english, re.I)
    if game_match:
        _make_game(game_match.group(2), game_match.group(1) or "")
        return

    if not args or english.lower() in ("help", "show commands"):
        _print("""
╔══════════════════════════════════════════════════════════════════════╗
║                         SIMPLE COMMANDS 3.7.0                        ║
╠══════════════════════════════════════════════════════════════════════╣
║  BASIC                                                                 ║
║  simple print <text>                                                   ║
║  simple say <text>   |   simple clear screen   |   simple what time is it
╠══════════════════════════════════════════════════════════════════════╣
║  FILES                                                                 ║
║  simple show my files   |   simple show my folders   |   simple show my drives
║  simple show files in <drive>:   |   simple show folders in <drive>:
║  simple find a file called <name> in <drive>:
║  simple create a folder called <name> in <drive>:
║  simple open <drive>:   |   simple go to <drive>:
║  simple open in simple <text.txt>
║  simple make a game where <description>
║  simple make a 2.5d game where <description>
╠══════════════════════════════════════════════════════════════════════╣
║  SYSTEM                                                                ║
║  simple show running programs   |   simple show my computer info
║  simple show wifi status   |   simple open notepad   |   simple open calculator
╠══════════════════════════════════════════════════════════════════════╣
║  VECTOR & WINDOWS                                                      ║
║  simple vector ip <address>
║  simple open window <HTML file path>
╠══════════════════════════════════════════════════════════════════════╣
║  LOCALHOST                                                             ║
║  simple localhost start <port>   |   simple localhost stop <port>
║  simple localhost status <port>
╠══════════════════════════════════════════════════════════════════════╣
║  UPDATES                                                               ║
║  simple offline   |   simple online
║  simple update   |   simple update localhost <port>   |   simple update timeline
╠══════════════════════════════════════════════════════════════════════╣
║  SCRIPTS                                                               ║
║  simple run <path to .smp or .spe file>
╚══════════════════════════════════════════════════════════════════════╝""")
        return

    low = english.lower()
    if re.fullmatch(r"(show my drives|show drives)", low):
        _show_drives()
        return
    if re.fullmatch(r"(show my files|show files)", low):
        _list_files(Path.cwd())
        return
    match = re.fullmatch(r"show files in ([a-z]):", english, re.I)
    if match:
        root = Path(match.group(1) + ":/" if os.name == "nt" else "/")
        _list_files(root)
        return
    match = re.fullmatch(r"show folders in ([a-z]):", english, re.I)
    if match:
        root = Path(match.group(1) + ":/" if os.name == "nt" else "/")
        _list_files(root, True)
        return
    if re.fullmatch(r"(show my folders|show folders)", low):
        _list_files(Path.cwd(), True)
        return
    if re.fullmatch(r"(show running programs|show my programs)", low):
        try:
            if os.name == "nt":
                subprocess.run(["tasklist"], check=False)
            else:
                subprocess.run(["ps", "-A"], check=False)
        except Exception as exc:
            _print(f"Could not list programs: {exc}")
        return
    match = re.fullmatch(r"open in simple (.+)", english, re.I)
    if match:
        path = Path(match.group(1).strip().strip('"')).expanduser()
        if path.suffix.lower() != ".txt":
            _print("SIMPLE viewer opens .txt files only.")
        elif not path.is_file():
            _print(f"Text file not found: {path}")
        else:
            _print(f"\n--- {path.name} ---")
            content = path.read_text(encoding="utf-8", errors="replace")
            _print(content if content else "(This file is empty.)")
            _print("--- End of file ---")
        return
    match = re.fullmatch(r"open ([a-z]):", english, re.I)
    if match:
        _open_path(Path(match.group(1) + ":/" if os.name == "nt" else "/"))
        return
    match = re.fullmatch(r"go to ([a-z]):", english, re.I)
    if match:
        target = Path(match.group(1) + ":/" if os.name == "nt" else "/")
        try:
            os.chdir(target)
            _print(f"Current folder: {Path.cwd()}")
        except Exception as exc:
            _print(f"Drive unavailable: {exc}")
        return
    match = re.fullmatch(r'create a folder called (.+?)(?: in ([a-z]):)?', english, re.I)
    if match:
        name = match.group(1).strip().strip('"')
        root = Path(match.group(2) + ":/" if os.name == "nt" else "/") if match.group(2) else Path.cwd()
        if not name or re.search(r'[\\\\/:*?"<>|]', name):
            _print("Invalid folder name.")
        elif not root.is_dir():
            _print(f"Location unavailable: {root}")
        else:
            target = root / name
            if target.exists():
                _print(f"Already exists: {target}")
            else:
                try:
                    target.mkdir()
                    _print(f"Created: {target}")
                except Exception as exc:
                    _print(f"Could not create folder: {exc}")
        return
    match = re.fullmatch(r"find a file called (.+?) in ([a-z]):", english, re.I)
    if match:
        name = match.group(1).strip().strip('"')
        root = Path(match.group(2) + ":/" if os.name == "nt" else "/")
        if not root.is_dir():
            _print(f"Drive unavailable: {root}")
        elif not name or re.search(r'[\\\\/:*?"<>|]', name):
            _print("Invalid file name.")
        else:
            count = 0
            for current, _, files in os.walk(root):
                if name in files:
                    _print(Path(current) / name)
                    count += 1
                    if count >= 100:
                        break
        return
    if low == "open notepad":
        command = ["notepad"] if os.name == "nt" else (["open", "-a", "TextEdit"] if sys.platform == "darwin" else ["nano"])
        try:
            subprocess.Popen(command)
        except Exception as exc:
            _print(f"Could not open text editor: {exc}")
        return
    if low == "open calculator":
        command = ["calc"] if os.name == "nt" else (["open", "-a", "Calculator"] if sys.platform == "darwin" else ["bc"])
        try:
            subprocess.Popen(command)
        except Exception as exc:
            _print(f"Could not open calculator: {exc}")
        return
    if low in ("what time is it", "show the time"):
        _print(_dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %Z"))
        return
    if low == "show my computer info":
        _print(f"System: {platform.system()} {platform.release()}")
        _print(f"Version: {platform.version()}")
        _print(f"Architecture: {platform.machine()}")
        _print(f"Processor: {platform.processor() or 'Unknown'}")
        _print(f"Python: {platform.python_version()}")
        return
    if low == "show wifi status":
        if os.name == "nt":
            try:
                subprocess.run(["netsh", "wlan", "show", "interfaces"], check=False)
            except Exception as exc:
                _print(f"Could not read Wi-Fi status: {exc}")
        else:
            try:
                subprocess.run(["ip", "addr"], check=False)
            except Exception as exc:
                _print("Wi-Fi status command is unavailable.")
        return
    if low.startswith("say "):
        _print(english[4:])
        return
    if low == "clear screen":
        os.system("cls" if os.name == "nt" else "clear")
        return
    if args[0].lower() == "print":
        _print(" ".join(args[1:]))
        return
    if args[0].lower() == "vector":
        if len(args) >= 3 and args[1].lower() == "ip":
            VECTOR_IP = args[2]
            _print(f"Vector IP: {VECTOR_IP}")
        else:
            _print("Usage: simple vector ip <address>")
        return
    if args[0].lower() == "open":
        if len(args) < 3 or args[1].lower() != "window":
            _print("Usage: simple open window <HTML file path or localhost URL>")
        else:
            _open_target(" ".join(args[2:]))
        return
    if args[0].lower() == "update":
        if OFFLINE:
            _print("SIMPLE is OFFLINE. The update command is unavailable in offline mode.")
            _print("Connect to the internet, then type: simple online")
            return
        if len(args) >= 2 and args[1].lower() == "timeline":
            _update_timeline()
            return
        if len(args) >= 3 and args[1].lower() == "localhost":
            _update()
            if len(args) >= 3:
                _localhost(["localhost", "start", args[2]])
            return
        _update()
        return
    if args[0].lower() == "localhost":
        _localhost(args)
        return
    _print(f"Unknown command: {args[0]}")


def main():
    if len(sys.argv) > 1:
        simple(*sys.argv[1:])
    else:
        _print("SIMPLE Python Profile " + VERSION)
        _print("Type: python simple_profile.py help")
        _print("To use the short command in your shell, create an alias named 'simple' for this file.")


if __name__ == "__main__":
    main()

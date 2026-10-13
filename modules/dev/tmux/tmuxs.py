#!/usr/bin/env python3
import asyncio
import json
import os
from pathlib import Path
import shlex
import shutil
import socket
import subprocess
import sys
from typing import Any, Awaitable, Callable, Optional

# Replaced by tmux.nix at build time; left untouched when run directly from the repo.
_SEARCH_PATHS_JSON = r'''@searchPaths@'''
_REMOTE_HOSTS_JSON = r'''@remoteHosts@'''


def _injected(raw: str) -> list[str]:
    return [] if raw.startswith("@") else json.loads(raw)


SEARCH_PATHS: list[str] = _injected(_SEARCH_PATHS_JSON)
REMOTE_HOSTS: list[str] = _injected(_REMOTE_HOSTS_JSON)

# XDG state paths
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "tmuxs"
HOSTS_FILE = STATE_DIR / "hosts.txt"

REMOTE_ENV = "export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; "
REMOTE_TIMEOUT = 4.0
SHELLS = {"fish", "bash", "zsh", "sh"}
WINDOW_FORMAT = "#{session_name}:#{window_index}|#{session_name}|#{window_name}|#{pane_current_command}"

IGNORED_DIRS = {
    "node_modules",
    "result",
    "target",
    "build",
    "__pycache__",
}


def run_cmd(cmd: list[str]) -> str:
    return subprocess.run(cmd, text=True, capture_output=True).stdout.strip()


def is_in_tmux() -> bool:
    return "TMUX" in os.environ


def is_local_host(host: str) -> bool:
    if host.lower() in ("localhost", "127.0.0.1", "::1"):
        return True
    local_name = socket.gethostname().lower()
    host_lower = host.lower()
    return host_lower == local_name or host_lower == local_name.split(".")[0]


def find_git_root(path: Path) -> Optional[Path]:
    try:
        current = path.resolve()
        while current != current.parent:
            if (current / ".git").exists():
                return current
            current = current.parent
    except OSError:
        pass
    return None


def discover_project_dirs(
    search_paths: list[str], max_depth: int = 2
) -> tuple[list[str], list[Path]]:
    dirs: list[str] = []
    discovered_roots: list[Path] = []
    seen_dirs: set[str] = set()
    seen_roots: set[Path] = set()
    search_roots = {
        Path(p).expanduser().resolve()
        for p in search_paths
        if Path(p).expanduser().is_dir()
    }

    def is_project(d: Path) -> bool:
        try:
            return (d / ".git").exists() or (d / ".project").exists()
        except OSError:
            return False

    def get_subdirs(p: Path) -> list[Path]:
        try:
            return sorted(
                [
                    entry
                    for entry in p.iterdir()
                    if entry.is_dir()
                    and not entry.name.startswith(".")
                    and entry.name not in IGNORED_DIRS
                ],
                key=lambda x: x.name.lower(),
            )
        except OSError:
            return []

    def add_discovered(p: Path, allow_search_root: bool = False) -> None:
        p_str = str(p)
        try:
            p_res = p.resolve()
        except OSError:
            p_res = p

        if not allow_search_root and p_res in search_roots:
            return

        if p_str not in seen_dirs and p_res not in seen_roots:
            seen_dirs.add(p_str)
            seen_roots.add(p_res)
            dirs.append(p_str)
            discovered_roots.append(p_res)

    visited_paths: set[Path] = set()

    def scan(d: Path, current_depth: int) -> None:
        try:
            d_res = d.resolve()
        except OSError:
            d_res = d

        if d_res in visited_paths:
            return
        visited_paths.add(d_res)

        if is_project(d):
            add_discovered(d)
            return

        subdirs = get_subdirs(d) if current_depth < max_depth else []
        has_child_project = any(is_project(sub) for sub in subdirs)

        if has_child_project:
            for sub in subdirs:
                scan(sub, current_depth + 1)
        else:
            add_discovered(d)

    for p_str in search_paths:
        base = Path(p_str).expanduser()
        if not base.is_dir():
            continue
        if is_project(base):
            add_discovered(base, allow_search_root=True)
            continue
        for child in get_subdirs(base):
            scan(child, current_depth=1)

    return dirs, discovered_roots


def get_ssh_hosts() -> list[str]:
    hosts: set[str] = set(REMOTE_HOSTS)
    if HOSTS_FILE.is_file():
        try:
            with HOSTS_FILE.open("r", encoding="utf-8") as f:
                for line in f:
                    h = line.strip()
                    if h:
                        hosts.add(h)
        except OSError:
            pass
    return sorted(hosts)


def remote_hosts() -> list[str]:
    return [h for h in get_ssh_hosts() if not is_local_host(h)]


def ssh_batch_cmd(host: str, script: str) -> list[str]:
    return [
        "ssh",
        "-o", "ConnectTimeout=2",
        "-o", "BatchMode=yes",
        "--",
        host,
        f"sh -l -c {shlex.quote(REMOTE_ENV + script)}",
    ]


async def ssh_run_async(host: str, script: str) -> Optional[str]:
    try:
        proc = await asyncio.create_subprocess_exec(
            *ssh_batch_cmd(host, script),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
    except OSError:
        return None
    try:
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=REMOTE_TIMEOUT)
    except (asyncio.TimeoutError, OSError):
        try:
            proc.kill()
            await proc.wait()
        except (ProcessLookupError, OSError):
            pass
        return None
    if proc.returncode != 0:
        return None
    return stdout.decode("utf-8", errors="replace")


async def gather_remote(fetch: Callable[[str], Awaitable[list[str]]]) -> list[str]:
    results = await asyncio.gather(*(fetch(h) for h in remote_hosts()))
    return [item for sublist in results for item in sublist]


def format_window_rows(lines: list[str], host: Optional[str] = None) -> list[str]:
    parsed = []
    max_sess = 12
    max_win = 12
    for line in lines:
        if not line.strip():
            continue
        parts = line.split("|", 3)
        if len(parts) < 4:
            continue
        target, sess_name, win_name, p_cmd = parts
        cmd_str = f"[{p_cmd}]" if p_cmd and p_cmd not in SHELLS else ""
        max_sess = max(max_sess, len(sess_name))
        max_win = max(max_win, len(win_name))
        parsed.append((target, sess_name, win_name, cmd_str))

    prefix = f"[{host}]".ljust(12) + " " if host else ""
    rows = []
    for target, sess_name, win_name, cmd_str in parsed:
        sess_col = sess_name.ljust(max_sess)
        win_col = win_name.ljust(max_win)
        display = f"{prefix}{sess_col}  ➜  {win_col}  {cmd_str}".rstrip()
        key = f"[{host}] {target}" if host else target
        rows.append(f"{key}\t{display}")
    return rows


async def fetch_remote_sessions(host: str) -> list[str]:
    out = await ssh_run_async(host, 'tmux -u list-sessions -F "#{session_name}" 2>/dev/null')
    if not out:
        return []
    return [f"{s} [{host}]" for s in out.strip().split("\n") if s]


async def fetch_remote_windows(host: str) -> list[str]:
    out = await ssh_run_async(host, f'tmux -u list-panes -a -F "{WINDOW_FORMAT}" 2>/dev/null')
    if not out:
        return []
    return format_window_rows(out.strip().split("\n"), host=host)


def get_local_sessions() -> list[str]:
    try:
        out = run_cmd(["tmux", "list-sessions", "-F", "#{session_name}"])
        return [line.strip() for line in out.split("\n") if line.strip()] if out else []
    except (subprocess.SubprocessError, OSError):
        return []


def run_fzf(choices: list[str], prompt: str = "> ", preview: Optional[str] = None, extra_args: Optional[list[str]] = None) -> str:
    cmd = ["fzf", "--prompt", prompt]
    if preview:
        cmd.extend(["--preview", preview])
    if extra_args:
        cmd.extend(extra_args)

    try:
        proc = subprocess.Popen(
            cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, encoding="utf-8"
        )
        stdout, _ = proc.communicate("\n".join(choices))
        return stdout.strip()
    except (subprocess.SubprocessError, OSError):
        return ""


def handle_connect_remote(host: str, sess: str, saved_session: Optional[str] = None) -> None:
    target_window = None
    if ":" in sess:
        target_window = sess
        sess = sess.split(":")[0]

    remote_script = "export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; clear; "
    if target_window:
        remote_script += f"tmux -u select-window -t {shlex.quote(target_window)} 2>/dev/null; "
    remote_script += f"exec tmux -u new-session -A -s {shlex.quote(sess)}; "

    ssh_cmd = [
        "ssh",
        "-t",
        "-o", "SendEnv=TERM",
        "-o", "SendEnv=COLORTERM",
        "-o", "SendEnv=LC_*",
        "-o", "SendEnv=LANG",
        "--",
        host,
        f"exec sh -l -c {shlex.quote(remote_script)}",
    ]
    subprocess.run(ssh_cmd)

    if saved_session:
        subprocess.run(["tmux", "attach-session", "-t", saved_session])


def connect_remote(host: str, sess: str) -> None:
    if is_in_tmux():
        saved_session = ""
        try:
            saved_session = run_cmd(["tmux", "display-message", "-p", "#S"])
        except Exception:
            pass
        cmd = f"{shlex.quote(sys.argv[0])} --connect-remote {shlex.quote(host)} {shlex.quote(sess)} {shlex.quote(saved_session)}"
        run_cmd(["tmux", "detach-client", "-E", cmd])
        sys.exit(0)
    else:
        handle_connect_remote(host, sess)


def sanitize_session_name(name: str) -> str:
    return name.replace(".", "-").replace(":", "-").replace("/", "-")


def local_session_paths() -> dict[str, str]:
    """Map session name -> resolved session start directory."""
    try:
        out = run_cmd(["tmux", "list-sessions", "-F", "#{session_name}\t#{session_path}"])
    except (subprocess.SubprocessError, OSError):
        return {}

    sessions: dict[str, str] = {}
    for line in out.split("\n"):
        if not line.strip():
            continue
        name, _, raw_path = line.partition("\t")
        if not raw_path:
            sessions[name] = ""
            continue
        try:
            sessions[name] = str(Path(raw_path).expanduser().resolve())
        except OSError:
            sessions[name] = raw_path
    return sessions


def attach_session(name: str) -> None:
    # "=" forces an exact session match; tmux otherwise falls back to prefix matching.
    target = f"={name}"
    if is_in_tmux():
        subprocess.run(["tmux", "switch-client", "-t", target])
    else:
        subprocess.run(["tmux", "attach", "-t", target])


def open_project(path: str) -> None:
    resolved = str(Path(path).expanduser().resolve())
    sessions = local_session_paths()
    for name, s_path in sessions.items():
        if s_path == resolved:
            attach_session(name)
            return

    p = Path(resolved)
    name = sanitize_session_name(p.name or "root")
    if name in sessions:
        # Same folder name, different project: disambiguate with the parent dir.
        name = sanitize_session_name(f"{p.parent.name}-{p.name}")
    if name not in sessions:
        subprocess.run(["tmux", "new-session", "-d", "-s", name, "-c", resolved, "-n", "nvim"])
        # Type nvim into a shell so quitting nvim leaves the window open.
        subprocess.run(["tmux", "send-keys", "-t", f"={name}:nvim", "nvim", "Enter"])
        subprocess.run(["tmux", "new-window", "-t", f"={name}:", "-c", resolved])
        subprocess.run(["tmux", "select-window", "-t", f"={name}:nvim"])
    attach_session(name)


def handle_preview(item: str) -> None:
    if item == "[<- Back]":
        print("Return to main menu.")
        return
    if item == "[Search Remote Sessions]":
        print("Search for active tmux sessions on your configured remote hosts.")
        return
    if item.startswith("[No remote sessions found"):
        print("No remote sessions are currently active. Press Enter or Esc to go back.")
        return
    if " [" in item and item.endswith("]"):
        sess, host = item.rsplit(" [", 1)
        host = host[:-1]
        print(f"=== Remote Session Preview ({host}) ===")
        remote_script = f"tmux -u list-windows -t {shlex.quote(sess)} -F '#I:#W #{{?window_active,(active),}}' && echo && tmux -u capture-pane -ep -t {shlex.quote(sess)}"
        out = run_cmd(ssh_batch_cmd(host, remote_script))
        print(out)
    else:
        print("=== Local Session Preview ===")
        out = run_cmd(
            [
                "tmux",
                "list-windows",
                "-t",
                item,
                "-F",
                "#I:#W #{?window_active,(active),}",
            ]
        )
        print(out)
        print()
        print("=== Active Pane Preview ===")
        out2 = run_cmd(["tmux", "capture-pane", "-ep", "-t", item])
        print(out2)


def handle_preview_window(target: str) -> None:
    if target == "[<- Back]":
        print("Return to main menu.")
        return
    if target == "[No local windows found]":
        print("No local windows are currently active.")
        return
    if target == "[Search Remote Windows]":
        print("Search for active tmux windows on your configured remote hosts.")
        return
    if target == "[No remote windows found]":
        print("No remote windows are currently active.")
        return
    if target.startswith("["):
        if "] " in target:
            host, sess_win = target[1:].split("] ", 1)
            print(f"=== Remote Window Preview ({host}) ===")
            remote_script = f"tmux -u capture-pane -ep -t {shlex.quote(sess_win)}"
            out = run_cmd(ssh_batch_cmd(host, remote_script))
            print(out)
        else:
            print("Invalid remote window target format.")
    else:
        out = run_cmd(["tmux", "capture-pane", "-ep", "-t", target])
        print(out)


def handle_dir_preview(item: str) -> None:
    if item == "[<- Back]":
        print("Return to main menu.")
        return
    if item == "[Add New Remote Host]":
        print("Manually add a new remote host to your local state.")
        return
    if item.startswith("[Remote] "):
        host = item[len("[Remote] "):]
        print(f"Create or attach a session on {host}.")
        return

    if (Path(item) / ".git").exists():
        print("=== Git ===")
        subprocess.run(["git", "-C", item, "-c", "color.status=always", "status", "-sb"])
        subprocess.run(["git", "-C", item, "log", "--oneline", "--color=always", "-5"])
        print()
    print("=== Content ===")
    if shutil.which("eza"):
        subprocess.run(["eza", "--level=1", "--color=always", "--icons", item])
    else:
        subprocess.run(["ls", "-F", item])


def pick_session(
    prompt_icon: str,
    on_local: Callable[[str], None],
    on_remote: Callable[[str, str], None],
) -> bool:
    preview = f"{shlex.quote(sys.argv[0])} --preview {{}}"
    while True:
        all_sessions = get_local_sessions() + ["[Search Remote Sessions]", "[<- Back]"]
        selected = run_fzf(all_sessions, prompt=f"{prompt_icon}  ", preview=preview)
        if not selected or selected == "[<- Back]":
            return False

        if selected != "[Search Remote Sessions]":
            on_local(selected)
            return True

        print("Fetching remote sessions...")
        remote_sessions = asyncio.run(gather_remote(fetch_remote_sessions))
        remote_choices = remote_sessions + ["[<- Back]"] if remote_sessions else ["[No remote sessions found]", "[<- Back]"]
        selected_remote = run_fzf(
            remote_choices, prompt=f"{prompt_icon} (remote)  ", preview=preview
        )
        if not selected_remote or selected_remote in ("[<- Back]", "[No remote sessions found]"):
            continue

        if " [" in selected_remote and selected_remote.endswith("]"):
            sess, host = selected_remote.rsplit(" [", 1)
            on_remote(host[:-1], sess)
            return True


def kill_local(name: str) -> None:
    subprocess.run(["tmux", "kill-session", "-t", f"={name}"])


def kill_remote(host: str, sess: str) -> None:
    try:
        subprocess.run(
            ssh_batch_cmd(host, f"tmux -u kill-session -t {shlex.quote(sess)}"),
            timeout=REMOTE_TIMEOUT,
        )
    except (subprocess.SubprocessError, OSError):
        pass


def handle_running() -> bool:
    return pick_session("󰖰", attach_session, connect_remote)


def handle_kill() -> bool:
    return pick_session("󰆴", kill_local, kill_remote)


def zoxide_scores() -> list[tuple[float, Path]]:
    if not shutil.which("zoxide"):
        return []
    try:
        out = run_cmd(["zoxide", "query", "--list", "--score"])
    except (subprocess.SubprocessError, OSError):
        return []

    result: list[tuple[float, Path]] = []
    for line in out.split("\n"):
        parts = line.split(maxsplit=1)
        if len(parts) != 2:
            continue
        try:
            score = float(parts[0])
        except ValueError:
            continue
        z_path = Path(parts[1]).expanduser()
        try:
            if not z_path.is_dir():
                continue
        except OSError:
            continue
        result.append((score, z_path))
    return result


def home_display(path: str) -> str:
    home = str(Path.home())
    if path == home or path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def project_candidates() -> list[str]:
    """Discovered projects plus zoxide dirs, ranked by zoxide frecency."""
    _, roots = discover_project_dirs(SEARCH_PATHS)
    search_roots = {str(Path(p).expanduser().resolve()) for p in SEARCH_PATHS}

    candidates: list[str] = [str(r) for r in roots]
    scores: dict[str, float] = {c: 0.0 for c in candidates}

    for score, z_path in zoxide_scores():
        try:
            z_res = z_path.resolve()
        except OSError:
            continue

        # Credit visits inside a discovered project to the deepest containing root.
        containing = [r for r in roots if z_res == r or z_res.is_relative_to(r)]
        if containing:
            best = max(containing, key=lambda r: len(r.parts))
            scores[str(best)] += score
            continue

        # Collapse subdirectories to git root if within a git repo
        candidate = str(find_git_root(z_path) or z_res)
        if candidate in search_roots:
            continue
        if candidate not in scores:
            candidates.append(candidate)
            scores[candidate] = 0.0
        scores[candidate] += score

    return sorted(candidates, key=lambda c: (-scores[c], home_display(c).lower()))


def handle_new(query: str = "") -> bool:
    active = set(local_session_paths().values())
    choices: list[str] = []
    for path in project_candidates():
        marker = "● " if path in active else "  "
        choices.append(f"{path}\t{marker}{home_display(path)}")

    for h in remote_hosts():
        choices.append(f"[Remote] {h}\t[Remote] {h}")
    choices.append("[Add New Remote Host]\t[Add New Remote Host]")
    choices.append("[<- Back]\t[<- Back]")

    extra_args = ["--delimiter=\t", "--with-nth=2", "--scheme=path"]
    if query:
        extra_args += ["--query", query]
    selected = run_fzf(
        choices,
        prompt="\uf07c  ",
        preview=f"{shlex.quote(sys.argv[0])} --dir-preview {{1}}",
        extra_args=extra_args,
    )
    key = selected.split("\t")[0]
    if not key or key == "[<- Back]":
        return False

    if key == "[Add New Remote Host]":
        new_host = input("Enter new hostname or IP: ").strip()
        if new_host:
            try:
                STATE_DIR.mkdir(parents=True, exist_ok=True)
                with HOSTS_FILE.open("a", encoding="utf-8") as f:
                    f.write(new_host + "\n")
                print(f"Added {new_host} to saved hosts!")
            except OSError as e:
                print(f"Failed to save host: {e}")
            sess_name = input("Session name (default 'main'): ").strip()
            if not sess_name:
                sess_name = "main"
            connect_remote(new_host, sess_name)
        return True

    if key.startswith("[Remote] "):
        host = key.split(" ", 1)[1]
        print(f"Creating new session on {host}")
        sess_name = input("Session name (default 'main'): ").strip()
        if not sess_name:
            sess_name = "main"
        connect_remote(host, sess_name)
    else:
        open_project(key)
    return True


def handle_windows() -> bool:
    # List all panes across all local sessions with structured delimiter
    try:
        out = run_cmd(["tmux", "list-panes", "-a", "-F", WINDOW_FORMAT])
        raw_lines = [line for line in out.split("\n") if line.strip()] if out else []
    except (subprocess.SubprocessError, OSError):
        raw_lines = []

    choices = format_window_rows(raw_lines) + ["[Search Remote Windows]", "[<- Back]"]

    selected = run_fzf(
        choices,
        prompt="󰖲  ",
        preview=f"{shlex.quote(sys.argv[0])} --preview-window {{1}}",
        extra_args=["--delimiter=\t", "--with-nth=2"],
    )
    if not selected or selected == "[<- Back]":
        return False

    if selected == "[Search Remote Windows]":
        print("Fetching remote windows...")
        remote_windows = asyncio.run(gather_remote(fetch_remote_windows))
        remote_choices = remote_windows + ["[<- Back]"] if remote_windows else ["[No remote windows found]", "[<- Back]"]
        selected_remote = run_fzf(
            remote_choices,
            prompt="󰖲 (remote)  ",
            preview=f"{shlex.quote(sys.argv[0])} --preview-window {{1}}",
            extra_args=["--delimiter=\t", "--with-nth=2"],
        )
        if not selected_remote or selected_remote in ("[<- Back]", "[No remote windows found]"):
            return False

        target = selected_remote.split("\t")[0]
        if target.startswith("["):
            host, sess_win = target[1:].split("] ", 1)
            connect_remote(host, sess_win)
        return True

    target = selected.split("\t")[0]
    if is_in_tmux():
        run_cmd(["tmux", "switch-client", "-t", target])
    else:
        subprocess.run(["tmux", "attach", "-t", target])
    return True


def main() -> None:
    dispatch: dict[str, Callable[..., Any]] = {
        "running": handle_running,
        "running-sessions": handle_running,
        "new": handle_new,
        "new-session": handle_new,
        "kill": handle_kill,
        "kill-session": handle_kill,
        "windows": handle_windows,
        "--windows": handle_windows,
    }

    if len(sys.argv) > 1:
        flag = sys.argv[1]
        if flag == "--preview":
            item = sys.argv[2] if len(sys.argv) > 2 else ""
            handle_preview(item)
            sys.exit(0)
        elif flag == "--preview-window":
            target = sys.argv[2] if len(sys.argv) > 2 else ""
            handle_preview_window(target)
            sys.exit(0)
        elif flag == "--dir-preview":
            path = sys.argv[2] if len(sys.argv) > 2 else "."
            handle_dir_preview(path)
            sys.exit(0)
        elif flag == "--connect-remote":
            host = sys.argv[2] if len(sys.argv) > 2 else ""
            sess = sys.argv[3] if len(sys.argv) > 3 else ""
            saved_session = sys.argv[4] if len(sys.argv) > 4 else None
            handle_connect_remote(host, sess, saved_session)
            sys.exit(0)
        elif flag in dispatch:
            dispatch[flag]()
            sys.exit(0)
        else:
            # Direct launch (e.g. `tmuxs nixos-config`, `tmuxs ~/src/foo`, `tmuxs .`).
            # Order: ".", explicit path, exact project name, zoxide, project substring;
            # if nothing matches, open the folder picker prefilled with the argument.
            arg = sys.argv[1]
            found_path: Optional[str] = None

            if arg == ".":
                found_path = str(Path.cwd())

            if not found_path and ("/" in arg or arg.startswith("~")):
                direct_path = Path(arg).expanduser()
                if direct_path.is_dir():
                    found_path = str(direct_path.resolve())

            project_dirs: list[str] = []
            if not found_path:
                project_dirs, _ = discover_project_dirs(SEARCH_PATHS)
                for d in project_dirs:
                    if Path(d).name.lower() == arg.lower():
                        found_path = d
                        break

            if not found_path and shutil.which("zoxide"):
                try:
                    z_match = run_cmd(["zoxide", "query", arg])
                    if z_match and Path(z_match).is_dir():
                        found_path = z_match
                except (subprocess.SubprocessError, OSError):
                    pass

            if not found_path and arg:
                for d in project_dirs:
                    if arg.lower() in Path(d).name.lower():
                        found_path = d
                        break

            if found_path:
                open_project(found_path)
            else:
                handle_new(query=arg)
            sys.exit(0)

    options = ["running", "new", "windows", "kill"]
    while True:
        selected = run_fzf(options, prompt="\uf135  ")
        if not selected:
            sys.exit(0)

        fn = dispatch.get(selected)
        if fn and fn():
            break


if __name__ == "__main__":
    main()

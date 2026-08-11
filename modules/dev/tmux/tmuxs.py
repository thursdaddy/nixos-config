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
import time
from typing import Optional

# Injected by Nix
SEARCH_PATHS = []


def run_cmd(cmd: list[str] | str, shell: bool = False, check: bool = False) -> str:
    res = subprocess.run(cmd, shell=shell, text=True, capture_output=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd}\n{res.stderr}")
    return res.stdout.strip()


def is_in_tmux() -> bool:
    return "TMUX" in os.environ


def detect_restore_cmd(p_cmd: str, p_title: str, w_name: str) -> Optional[str]:
    c_cmd = (p_cmd or "").strip().lower()
    c_title = (p_title or "").strip().lower()
    c_name = (w_name or "").strip().lower()

    if "nvim" in c_cmd or "nvim" in c_title or c_name == "nvim":
        return "nvim"
    if "agy" in c_cmd or "agy" in c_title or c_name == "agy":
        return "agy"

    known_tools = {
        "lazygit", "htop", "btop", "yazi", "ranger", "ncdu", "k9s",
        "gh", "gitmux", "serpl"
    }
    for tool in known_tools:
        if tool in c_cmd or tool in c_title:
            return tool

    shells = {"fish", "bash", "zsh", "sh", "dash", "none", "null"}
    if c_cmd and c_cmd not in shells and c_cmd not in ("python", "python3", "node"):
        return p_cmd.strip()

    return None


def save_session_layout(sess: str) -> bool:
    if not sess or sess.startswith("["):
        return False
    layouts_dir = Path.home() / ".local/state/tmuxs/layouts"
    try:
        layouts_dir.mkdir(parents=True, exist_ok=True)
    except OSError:
        return False

    format_str = "#{window_index}|#{window_name}|#{window_layout}|#{window_active}|#{pane_index}|#{pane_current_path}|#{pane_current_command}|#{pane_title}|#{pane_active}"
    try:
        win_out = run_cmd(["tmux", "list-panes", "-s", "-t", sess, "-F", format_str])
        if not win_out:
            return False

        windows_dict = {}
        for line in win_out.split("\n"):
            if not line.strip():
                continue
            parts = line.split("|", 8)
            if len(parts) < 9:
                continue

            try:
                w_idx = int(parts[0])
            except ValueError:
                continue
            w_name = parts[1]
            w_layout = parts[2]
            w_active = (parts[3] == "1")

            try:
                p_idx = int(parts[4])
            except ValueError:
                continue
            p_path = parts[5]
            p_cmd = parts[6]
            p_title = parts[7]
            p_active = (parts[8] == "1")

            if w_idx not in windows_dict:
                windows_dict[w_idx] = {
                    "index": w_idx,
                    "name": w_name,
                    "layout": w_layout,
                    "active": w_active,
                    "panes": []
                }

            r_cmd = detect_restore_cmd(p_cmd, p_title, w_name)

            windows_dict[w_idx]["panes"].append({
                "index": p_idx,
                "path": p_path,
                "cmd": r_cmd,
                "active": p_active
            })

        windows_data = list(windows_dict.values())
        windows_data.sort(key=lambda x: x["index"])

        layout_file = layouts_dir / f"{sess}.json"
        with layout_file.open("w", encoding="utf-8") as f:
            json.dump(windows_data, f, indent=2)
        return True
    except (subprocess.SubprocessError, RuntimeError, OSError, ValueError):
        return False


def save_all_layouts() -> list[str]:
    saved = []
    try:
        out = run_cmd(["tmux", "list-sessions", "-F", "#{session_name}"])
        if out:
            sessions = [line.strip() for line in out.split("\n") if line.strip()]
            for sess in sessions:
                if save_session_layout(sess):
                    saved.append(sess)
    except (subprocess.SubprocessError, RuntimeError, OSError):
        pass
    return saved


def handle_save_session() -> bool:
    choices: list[str] = []
    curr_sess = None
    if is_in_tmux():
        try:
            curr_sess = run_cmd(["tmux", "display-message", "-p", "#S"])
            if curr_sess:
                choices.append(f"Save current session ('{curr_sess}')")
        except Exception:
            pass
    choices.append("Save all active sessions")
    choices.append("[<- Back]")

    selected = run_fzf(choices, prompt="󰆓  ")
    if not selected or selected == "[<- Back]":
        return False

    if curr_sess and selected == f"Save current session ('{curr_sess}')":
        if save_session_layout(curr_sess):
            print(f"Successfully saved layout for session '{curr_sess}'!")
        else:
            print(f"Failed to save layout for session '{curr_sess}'.")
        return True
    elif selected == "Save all active sessions":
        saved = save_all_layouts()
        if saved:
            print(f"Successfully saved layouts for {len(saved)} session(s): {', '.join(saved)}")
        else:
            print("No active sessions to save.")
        return True
    return False




def get_ssh_hosts() -> list[str]:
    hosts: set[str] = set()
    hosts_file = Path.home() / ".local/state/tmuxs/hosts.txt"
    if hosts_file.is_file():
        try:
            with hosts_file.open("r", encoding="utf-8") as f:
                for line in f:
                    h = line.strip()
                    if h:
                        hosts.add(h)
        except OSError:
            pass
    return sorted(list(hosts))


async def fetch_remote_sessions(host: str) -> list[str]:
    # Fast async SSH call
    cmd = [
        "ssh",
        "-o",
        "ConnectTimeout=2",
        "-o",
        "BatchMode=yes",
        host,
        "sh -l -c 'export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; tmux -u list-sessions -F \"#{session_name}\" 2>/dev/null'",
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=1.5)
        if proc.returncode == 0 and stdout:
            sessions = stdout.decode("utf-8", errors="replace").strip().split("\n")
            return [f"{s} [{host}]" for s in sessions if s]
    except (asyncio.TimeoutError, TimeoutError):
        try:
            proc.kill()
            await proc.wait()
        except ProcessLookupError:
            pass
    except OSError:
        pass
    return []


async def get_all_remote_sessions() -> list[str]:
    hosts = get_ssh_hosts()
    local_hostname = socket.gethostname()
    tasks = [fetch_remote_sessions(h) for h in hosts if h != local_hostname]
    results = await asyncio.gather(*tasks)
    return [item for sublist in results for item in sublist]


async def fetch_remote_windows(host: str) -> list[str]:
    format_str = f"#{{session_name}}:#{{window_index}}|#{{session_name}}|#{{window_name}}|#{{pane_current_command}}"
    cmd = [
        "ssh",
        "-o",
        "ConnectTimeout=2",
        "-o",
        "BatchMode=yes",
        host,
        f"sh -l -c 'export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; tmux -u list-panes -a -F \"{format_str}\" 2>/dev/null'",
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=1.5)
        if proc.returncode == 0 and stdout:
            lines = stdout.decode("utf-8", errors="replace").strip().split("\n")
            parsed = []
            max_sess = 12
            max_win = 12
            for line in lines:
                if not line.strip():
                    continue
                parts = line.split("|", 3)
                if len(parts) < 4:
                    continue
                target, sess_name, win_name, p_cmd = parts[0], parts[1], parts[2], parts[3]
                cmd_str = f"[{p_cmd}]" if p_cmd and p_cmd not in ("fish", "bash", "zsh", "sh") else ""
                max_sess = max(max_sess, len(sess_name))
                max_win = max(max_win, len(win_name))
                parsed.append((target, sess_name, win_name, cmd_str))

            result = []
            host_tag = f"[{host}]".ljust(12)
            for target, sess_name, win_name, cmd_str in parsed:
                sess_col = sess_name.ljust(max_sess)
                win_col = win_name.ljust(max_win)
                display = f"{host_tag} {sess_col}  ➜  {win_col}  {cmd_str}".rstrip()
                result.append(f"[{host}] {target}\t{display}")
            return result
    except (asyncio.TimeoutError, TimeoutError, OSError):
        pass
    return []


async def get_all_remote_windows() -> list[str]:
    hosts = get_ssh_hosts()
    local_hostname = socket.gethostname()
    tasks = [fetch_remote_windows(h) for h in hosts if h != local_hostname]
    results = await asyncio.gather(*tasks)
    return [item for sublist in results for item in sublist]


def get_local_sessions() -> list[str]:
    try:
        out = run_cmd(["tmux", "list-sessions", "-F", "#{session_name}"])
        return [line.strip() for line in out.split("\n") if line.strip()] if out else []
    except (subprocess.SubprocessError, RuntimeError):
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


def handle_connect_remote(host: str, sess: str, saved_session: Optional[str] = None, passed_socket: Optional[str] = None) -> None:
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


def get_restore_cmd(item: dict) -> Optional[str]:
    w_cmd = str(item.get("cmd", "") or "").strip()
    w_cmd_lower = w_cmd.lower()
    w_name_lower = str(item.get("name", "") or "").strip().lower()

    if "nvim" in w_cmd_lower or w_name_lower == "nvim":
        return "nvim"
    if "agy" in w_cmd_lower or w_name_lower == "agy":
        return "agy"

    known_tools = {
        "lazygit", "htop", "btop", "yazi", "ranger", "ncdu", "k9s",
        "gh", "gitmux", "serpl"
    }
    for tool in known_tools:
        if tool in w_cmd_lower:
            return tool

    shells = {"fish", "bash", "zsh", "sh", "dash", "none", "null"}
    if w_cmd and w_cmd_lower not in shells:
        return w_cmd

    return None


def start_or_attach_local(name: str, path: Optional[str] = None, restore_layout: bool = False) -> None:
    safe_name = name.replace(".", "-").replace(":", "-")

    if restore_layout:
        if subprocess.run(["tmux", "has-session", "-t", safe_name], capture_output=True).returncode == 0:
            subprocess.run(["tmux", "kill-session", "-t", safe_name])

    session_exists = subprocess.run(["tmux", "has-session", "-t", safe_name], capture_output=True).returncode == 0
    if not session_exists:
        layout_restored = False
        if restore_layout:
            layouts_dir = Path.home() / ".local/state/tmuxs/layouts"
            layout_file = layouts_dir / f"{safe_name}.json"
            if layout_file.is_file():
                try:
                    with layout_file.open("r", encoding="utf-8") as f:
                        windows_data = json.load(f)
                    if isinstance(windows_data, list) and windows_data:
                        active_win_idx = None

                        for w_idx, win in enumerate(windows_data):
                            w_name = win.get("name", f"win{w_idx+1}")
                            w_layout = win.get("layout")
                            win_index = win.get("index", w_idx + 1)
                            if win.get("active"):
                                active_win_idx = win_index

                            if "panes" in win and isinstance(win["panes"], list) and win["panes"]:
                                panes = win["panes"]
                            else:
                                panes = [{
                                    "index": 1,
                                    "path": win.get("path", path or str(Path.home())),
                                    "cmd": win.get("cmd"),
                                    "active": True
                                }]

                            pane0 = panes[0]
                            pane0_path = pane0.get("path") or path or str(Path.home())
                            
                            if w_idx == 0:
                                subprocess.run([
                                    "tmux", "new-session", "-d", "-s", safe_name,
                                    "-c", pane0_path, "-n", w_name
                                ], check=True)
                            else:
                                subprocess.run([
                                    "tmux", "new-window", "-t", safe_name,
                                    "-c", pane0_path, "-n", w_name
                                ], check=True)

                            win_target = f"{safe_name}:{w_name}"
                            
                            r_cmd0 = get_restore_cmd(pane0)
                            if r_cmd0:
                                time.sleep(0.05)
                                subprocess.run([
                                    "tmux", "send-keys", "-t", f"{win_target}.{pane0.get('index', 1)}",
                                    r_cmd0, "C-m"
                                ])

                            active_pane_idx = None
                            if pane0.get("active"):
                                active_pane_idx = pane0.get("index", 1)

                            for p in panes[1:]:
                                p_path = p.get("path") or pane0_path
                                subprocess.run([
                                    "tmux", "split-window", "-t", win_target,
                                    "-c", p_path
                                ])
                                p_idx = p.get("index", 2)
                                p_target = f"{win_target}.{p_idx}"
                                r_cmd = get_restore_cmd(p)
                                if r_cmd:
                                    time.sleep(0.05)
                                    subprocess.run([
                                        "tmux", "send-keys", "-t", p_target,
                                        r_cmd, "C-m"
                                    ])
                                if p.get("active"):
                                    active_pane_idx = p_idx

                            if w_layout:
                                subprocess.run(["tmux", "select-layout", "-t", win_target, w_layout])

                            if active_pane_idx is not None:
                                subprocess.run(["tmux", "select-pane", "-t", f"{win_target}.{active_pane_idx}"])

                        if active_win_idx is not None:
                            subprocess.run(["tmux", "select-window", "-t", f"{safe_name}:{active_win_idx}"])

                        layout_restored = True
                except Exception:
                    pass

        if not layout_restored:
            if path:
                subprocess.run([
                    "tmux", "new-session", "-d", "-s", safe_name,
                    "-c", path, "-n", "nvim"
                ])
                time.sleep(0.05)
                subprocess.run(["tmux", "send-keys", "-t", f"{safe_name}:nvim", "nvim", "C-m"])
                subprocess.run(["tmux", "new-window", "-c", path, "-t", safe_name])
                subprocess.run(["tmux", "select-window", "-t", f"{safe_name}:nvim"])
            else:
                subprocess.run(["tmux", "new-session", "-d", "-s", safe_name])

    if is_in_tmux():
        subprocess.run(["tmux", "switch-client", "-t", safe_name])
    else:
        subprocess.run(["tmux", "attach", "-t", safe_name])


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
        remote_script = f"export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; tmux -u list-windows -t {shlex.quote(sess)} -F '#I:#W #{{?window_active,(active),}}' && echo && tmux -u capture-pane -ep -t {shlex.quote(sess)}"
        out = run_cmd(
            [
                "ssh",
                "-o",
                "ConnectTimeout=2",
                "-o",
                "BatchMode=yes",
                host,
                f"sh -l -c {shlex.quote(remote_script)}",
            ]
        )
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
            remote_script = f"export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; tmux -u capture-pane -ep -t {shlex.quote(sess_win)}"
            out = run_cmd(
                [
                    "ssh",
                    "-o",
                    "ConnectTimeout=2",
                    "-o",
                    "BatchMode=yes",
                    host,
                    f"sh -l -c {shlex.quote(remote_script)}",
                ]
            )
            print(out)
        else:
            print("Invalid remote window target format.")
    else:
        out = run_cmd(["tmux", "capture-pane", "-ep", "-t", target])
        print(out)


def handle_dir_preview(path: str) -> None:
    print("=== Content ===")
    if shutil.which("eza"):
        subprocess.run(
            ["eza", "--tree", "--level=2", "--color=always", "--icons", path]
        )
    else:
        subprocess.run(["ls", "-F", path])


def handle_running() -> bool:
    while True:
        local_sessions = get_local_sessions()
        all_sessions = local_sessions + ["[Search Remote Sessions]", "[<- Back]"]

        selected = run_fzf(
            all_sessions, prompt="󰖰  ", preview=f"{shlex.quote(sys.argv[0])} --preview {{}}"
        )
        if not selected or selected == "[<- Back]":
            return False

        if selected == "[Search Remote Sessions]":
            print("Fetching remote sessions...")
            remote_sessions = asyncio.run(get_all_remote_sessions())
            remote_choices = remote_sessions + ["[<- Back]"] if remote_sessions else ["[No remote sessions found]", "[<- Back]"]
            selected_remote = run_fzf(
                remote_choices, prompt="󰖰 (remote)  ", preview=f"{shlex.quote(sys.argv[0])} --preview {{}}"
            )
            if not selected_remote or selected_remote in ("[<- Back]", "[No remote sessions found]"):
                continue

            if " [" in selected_remote and selected_remote.endswith("]"):
                sess, host = selected_remote.rsplit(" [", 1)
                host = host[:-1]
                connect_remote(host, sess)
                return True
        else:
            start_or_attach_local(selected)
            return True


def handle_kill() -> bool:
    while True:
        local_sessions = get_local_sessions()
        all_sessions = local_sessions + ["[Search Remote Sessions]", "[<- Back]"]

        selected = run_fzf(
            all_sessions, prompt="󰆴  ", preview=f"{shlex.quote(sys.argv[0])} --preview {{}}"
        )
        if not selected or selected == "[<- Back]":
            return False

        if selected == "[Search Remote Sessions]":
            print("Fetching remote sessions...")
            remote_sessions = asyncio.run(get_all_remote_sessions())
            remote_choices = remote_sessions + ["[<- Back]"] if remote_sessions else ["[No remote sessions found]", "[<- Back]"]
            selected_remote = run_fzf(
                remote_choices, prompt="󰆴 (remote)  ", preview=f"{shlex.quote(sys.argv[0])} --preview {{}}"
            )
            if not selected_remote or selected_remote in ("[<- Back]", "[No remote sessions found]"):
                continue

            if " [" in selected_remote and selected_remote.endswith("]"):
                sess, host = selected_remote.rsplit(" [", 1)
                host = host[:-1]
                # Fast async SSH kill command wrapped in sh -l -c to find the socket
                remote_script = f"export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TERM=xterm-256color COLORTERM=truecolor; tmux -u kill-session -t {shlex.quote(sess)}"
                subprocess.run(
                    [
                        "ssh",
                        "-o",
                        "ConnectTimeout=2",
                        "-o",
                        "BatchMode=yes",
                        host,
                        f"sh -l -c {shlex.quote(remote_script)}",
                    ]
                )
                return True
        else:
            subprocess.run(["tmux", "kill-session", "-t", selected])
            return True


def handle_new() -> bool:
    choices: list[str] = []
    # Add remotes first
    hosts = get_ssh_hosts()
    local_host = socket.gethostname()
    for h in hosts:
        if h != local_host:
            choices.append(f"[Remote] {h}")

    # Add local dirs
    dirs: list[str] = []
    for p_str in SEARCH_PATHS:
        p = Path(p_str)
        if p.is_dir():
            try:
                for entry in p.iterdir():
                    if entry.is_dir():
                        dirs.append(str(entry))
            except OSError:
                pass

    # Add zoxide
    if shutil.which("zoxide"):
        try:
            z_dirs = run_cmd(["zoxide", "query", "-l"]).split("\n")
            for z in z_dirs:
                if z:
                    z_path = Path(z)
                    if z_path.is_dir() and str(z_path) not in dirs:
                        dirs.append(str(z_path))
        except (subprocess.SubprocessError, RuntimeError):
            pass

    choices.extend(dirs)
    choices.append("[Add New Remote Host]")
    choices.append("[<- Back]")

    preview_cmd = f'bash -c \'if [[ "$1" == "[<- Back]" ]]; then echo "Return to main menu"; elif [[ "$1" == "[Add New Remote Host]" ]]; then echo "Manually add a new remote host to your local state"; elif [[ "$1" == \\[Remote\\]* ]]; then echo "Create new session on remote host"; else "$0" --dir-preview "$1"; fi\' {shlex.quote(sys.argv[0])} {{}}'
    selected = run_fzf(choices, prompt="  ", preview=preview_cmd)
    if not selected or selected == "[<- Back]":
        return False

    if selected == "[Add New Remote Host]":
        new_host = input("Enter new hostname or IP: ").strip()
        if new_host:
            state_dir = Path.home() / ".local/state/tmuxs"
            try:
                state_dir.mkdir(parents=True, exist_ok=True)
                with (state_dir / "hosts.txt").open("a", encoding="utf-8") as f:
                    f.write(new_host + "\n")
                print(f"Added {new_host} to saved hosts!")
            except OSError as e:
                print(f"Failed to save host: {e}")
            sess_name = input("Session name (default 'main'): ").strip()
            if not sess_name:
                sess_name = "main"
            connect_remote(new_host, sess_name)
        return True

    if selected.startswith("[Remote] "):
        host = selected.split(" ", 1)[1]
        print(f"Creating new session on {host}")
        sess_name = input("Session name (default 'main'): ").strip()
        if not sess_name:
            sess_name = "main"
        connect_remote(host, sess_name)
    else:
        basename = Path(selected).name
        start_or_attach_local(basename, selected)
    return True


def handle_windows() -> bool:
    # List all panes across all local sessions with structured delimiter
    format_str = "#{session_name}:#{window_index}|#{session_name}|#{window_name}|#{pane_current_command}"
    try:
        out = run_cmd(["tmux", "list-panes", "-a", "-F", format_str])
        raw_lines = [line for line in out.split("\n") if line.strip()] if out else []
    except (subprocess.SubprocessError, RuntimeError):
        raw_lines = []

    parsed = []
    max_sess = 12
    max_win = 12

    for line in raw_lines:
        parts = line.split("|", 3)
        if len(parts) < 4:
            continue
        target, sess_name, win_name, p_cmd = parts[0], parts[1], parts[2], parts[3]
        cmd_str = f"[{p_cmd}]" if p_cmd and p_cmd not in ("fish", "bash", "zsh", "sh") else ""
        max_sess = max(max_sess, len(sess_name))
        max_win = max(max_win, len(win_name))
        parsed.append((target, sess_name, win_name, cmd_str))

    formatted_choices = []
    for target, sess_name, win_name, cmd_str in parsed:
        sess_col = sess_name.ljust(max_sess)
        win_col = win_name.ljust(max_win)
        display = f"{sess_col}  ➜  {win_col}  {cmd_str}".rstrip()
        formatted_choices.append(f"{target}\t{display}")

    choices = formatted_choices + ["[Search Remote Windows]", "[<- Back]"]

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
        remote_windows = asyncio.run(get_all_remote_windows())
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
    run_cmd(["tmux", "switch-client", "-t", target])
    return True


def handle_preview_layout(sess: str) -> None:
    layouts_dir = Path.home() / ".local/state/tmuxs/layouts"
    layout_file = layouts_dir / f"{sess}.json"
    if not layout_file.is_file():
        print(f"No saved layout found for '{sess}'.")
        return
    try:
        with layout_file.open("r", encoding="utf-8") as f:
            windows_data = json.load(f)
        print(f"=== Saved Layout Preview ({sess}) ===")
        if isinstance(windows_data, list):
            for win in windows_data:
                w_idx = win.get("index", "?")
                w_name = win.get("name", "")
                panes = win.get("panes", [])
                pane_cmds = [p.get("cmd") or "shell" for p in panes if isinstance(p, dict)]
                print(f"Window {w_idx}: {w_name} [{', '.join(pane_cmds)}]")
                for p in panes:
                    if isinstance(p, dict):
                        p_idx = p.get("index", "?")
                        p_path = p.get("path", "")
                        p_cmd = p.get("cmd") or "shell"
                        print(f"  Pane {p_idx}: {p_cmd} ({p_path})")
    except Exception as e:
        print(f"Error reading layout file: {e}")


def handle_restore_session(target_sess: Optional[str] = None) -> bool:
    layouts_dir = Path.home() / ".local/state/tmuxs/layouts"
    if not layouts_dir.is_dir():
        print("No saved layouts directory found (~/.local/state/tmuxs/layouts).")
        return False

    saved_files = list(layouts_dir.glob("*.json"))
    saved_sessions = sorted([f.stem for f in saved_files])

    if target_sess:
        if target_sess in saved_sessions:
            start_or_attach_local(target_sess, restore_layout=True)
            return True
        else:
            safe_target = target_sess.replace(".", "-").replace(":", "-")
            if safe_target in saved_sessions:
                start_or_attach_local(safe_target, restore_layout=True)
                return True
            print(f"No saved layout found for '{target_sess}'.")
            return False

    if not saved_sessions:
        print("No saved session layouts found in ~/.local/state/tmuxs/layouts.")
        return False

    choices = saved_sessions + ["[<- Back]"]
    preview_cmd = f'bash -c \'if [[ "$1" == "[<- Back]" ]]; then echo "Return to main menu"; else "$0" --preview-layout "$1"; fi\' {shlex.quote(sys.argv[0])} {{}}'
    selected = run_fzf(choices, prompt="󰁯  ", preview=preview_cmd)
    if not selected or selected == "[<- Back]":
        return False

    start_or_attach_local(selected, restore_layout=True)
    return True


def main() -> None:
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
        elif flag == "--preview-layout":
            sess = sys.argv[2] if len(sys.argv) > 2 else ""
            handle_preview_layout(sess)
            sys.exit(0)
        elif flag == "--dir-preview":
            path = sys.argv[2] if len(sys.argv) > 2 else "."
            handle_dir_preview(path)
            sys.exit(0)
        elif flag in ("--windows", "windows"):
            handle_windows()
            sys.exit(0)
        elif flag in ("running-sessions", "running"):
            handle_running()
            sys.exit(0)
        elif flag in ("new-session", "new"):
            handle_new()
            sys.exit(0)
        elif flag in ("kill-session", "kill"):
            handle_kill()
            sys.exit(0)
        elif flag in ("--restore", "-r", "restore-sessions", "restore-session", "restore"):
            target_sess = sys.argv[2] if len(sys.argv) > 2 else None
            handle_restore_session(target_sess)
            sys.exit(0)
        elif flag == "--connect-remote":
            host = sys.argv[2] if len(sys.argv) > 2 else ""
            sess = sys.argv[3] if len(sys.argv) > 3 else ""
            saved_session = sys.argv[4] if len(sys.argv) > 4 else None
            passed_socket = sys.argv[5] if len(sys.argv) > 5 else None
            handle_connect_remote(host, sess, saved_session, passed_socket)
            sys.exit(0)
        elif flag in ("--save-layouts", "save-sessions", "save-session", "save"):
            handle_save_session()
            sys.exit(0)
        else:
            # Handle direct session/dir launch (e.g. `tmuxs nixos-config`)
            arg = sys.argv[1]
            found_path = None

            if arg == ".":
                found_path = str(Path.cwd())
                arg = Path.cwd().name or "root"
            else:
                for p_str in SEARCH_PATHS:
                    full_path = Path(p_str) / arg
                    if full_path.is_dir():
                        found_path = str(full_path)
                        break

            if found_path:
                start_or_attach_local(arg, found_path)
            else:
                # Fallback to pure session name
                start_or_attach_local(arg)
            sys.exit(0)

    options = ["running", "new", "restore", "save", "kill"]

    while True:
        selected = run_fzf(options, prompt="  ")
        if not selected:
            sys.exit(0)

        done = False
        if selected in ("kill-session", "kill"):
            done = handle_kill()
        elif selected in ("save-sessions", "save-session", "save"):
            done = handle_save_session()
        elif selected in ("restore-sessions", "restore-session", "restore"):
            done = handle_restore_session()
        elif selected in ("new-session", "new"):
            done = handle_new()
        elif selected in ("running-sessions", "running"):
            done = handle_running()

        if done:
            break



if __name__ == "__main__":
    main()

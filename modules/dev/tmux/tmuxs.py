#!/usr/bin/env python3
import asyncio
import os
import shlex
import shutil
import subprocess
import sys

# Injected by Nix
SEARCH_PATHS = []


def run_cmd(cmd, shell=False, check=False):
    res = subprocess.run(cmd, shell=shell, text=True, capture_output=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\n{res.stderr}")
    return res.stdout.strip()


def is_in_tmux():
    return "TMUX" in os.environ


def get_ssh_hosts():
    hosts = set()
    hosts_file = os.path.expanduser("~/.local/state/tmuxs/hosts.txt")
    if os.path.exists(hosts_file):
        with open(hosts_file, "r") as f:
            for line in f:
                h = line.strip()
                if h:
                    hosts.add(h)
    return sorted(list(hosts))


async def fetch_remote_sessions(host):
    # Fast async SSH call
    cmd = [
        "ssh",
        "-o",
        "ConnectTimeout=2",
        "-o",
        "BatchMode=yes",
        host,
        "sh -l -c 'tmux list-sessions -F \"#{session_name}\" 2>/dev/null'",
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=1.5)
        if proc.returncode == 0 and stdout:
            sessions = stdout.decode().strip().split("\n")
            return [f"{s} [{host}]" for s in sessions if s]
    except asyncio.TimeoutError:
        try:
            proc.kill()
        except ProcessLookupError:
            pass
    return []


async def get_all_remote_sessions():
    hosts = get_ssh_hosts()
    tasks = [fetch_remote_sessions(h) for h in hosts if h != run_cmd(["hostname"])]
    results = await asyncio.gather(*tasks)
    return [item for sublist in results for item in sublist]


async def fetch_remote_windows(host):
    format_str = f"#{{session_name}}:#{{window_index}}\t[{host}]  #{{session_name}}  ➜  #{{window_name}}  #{{?#{{==:#{{pane_current_command}},fish}},,[#{{pane_current_command}}]}}"
    cmd = [
        "ssh",
        "-o",
        "ConnectTimeout=2",
        "-o",
        "BatchMode=yes",
        host,
        f"sh -l -c 'tmux list-panes -a -F \"{format_str}\" 2>/dev/null'",
    ]
    proc = await asyncio.create_subprocess_exec(
        *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=1.5)
        if proc.returncode == 0 and stdout:
            windows = stdout.decode().strip().split("\n")
            return [f"[{host}] {w}" for w in windows if w]
    except asyncio.TimeoutError:
        try:
            proc.kill()
        except ProcessLookupError:
            pass
    return []


async def get_all_remote_windows():
    hosts = get_ssh_hosts()
    tasks = [fetch_remote_windows(h) for h in hosts if h != run_cmd(["hostname"])]
    results = await asyncio.gather(*tasks)
    return [item for sublist in results for item in sublist]


def get_local_sessions():
    out = run_cmd(["tmux", "list-sessions", "-F", "#{session_name}"])
    return out.split("\n") if out else []


def run_fzf(choices, prompt="> ", preview=None, extra_args=None):
    cmd = ["fzf", "--prompt", prompt]
    if preview:
        cmd.extend(["--preview", preview])
    if extra_args:
        cmd.extend(extra_args)

    proc = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
    )
    stdout, _ = proc.communicate("\n".join(choices))
    return stdout.strip()


def handle_connect_remote():
    host = sys.argv[2]
    sess = sys.argv[3]
    saved_session = sys.argv[4] if len(sys.argv) > 4 else None

    target_window = None
    if ":" in sess:
        target_window = sess
        sess = sess.split(":")[0]

    local_socket = run_cmd(["tmux", "display-message", "-p", "#{socket_path}"])
    remote_socket = f"/tmp/tmuxs-fwd-{host}-{os.getpid()}.sock"

    remote_script = f"clear; tmux set-environment -g TMSP_LOCAL_SOCKET {shlex.quote(remote_socket)} 2>/dev/null; "
    if target_window:
        remote_script += (
            f"tmux select-window -t {shlex.quote(target_window)} 2>/dev/null; "
        )
    remote_script += f"tmux new-session -As {shlex.quote(sess)}; "
    remote_script += f"tmux set-environment -gu TMSP_LOCAL_SOCKET 2>/dev/null; rm -f {shlex.quote(remote_socket)} 2>/dev/null"

    ssh_cmd = [
        "ssh",
        "-t",
        "-R",
        f"{remote_socket}:{local_socket}",
        host,
        f"exec sh -l -c {shlex.quote(remote_script)}",
    ]
    subprocess.run(ssh_cmd)

    # Check if a jump was requested from the remote side
    pending_remote = run_cmd(["tmux", "show-environment", "-g", "TMSP_PENDING_REMOTE"])
    pending_local = run_cmd(["tmux", "show-environment", "-g", "TMSP_PENDING_LOCAL"])

    if pending_remote and pending_remote.startswith("TMSP_PENDING_REMOTE="):
        run_cmd(["tmux", "set-environment", "-gu", "TMSP_PENDING_REMOTE"])
        target = pending_remote.split("=", 1)[1]
        r_host, r_sess = target.split(":", 1)
        sys.argv[2] = r_host
        sys.argv[3] = r_sess
        handle_connect_remote()
    elif pending_local and pending_local.startswith("TMSP_PENDING_LOCAL="):
        run_cmd(["tmux", "set-environment", "-gu", "TMSP_PENDING_LOCAL"])
        target = pending_local.split("=", 1)[1]

        target_sess = run_cmd(
            ["tmux", "list-panes", "-a", "-F", "#{pane_id}|#{session_name}"]
        ).split("\n")
        sess_name = saved_session
        for line in target_sess:
            if line.startswith(f"{target}|"):
                sess_name = line.split("|", 1)[1]
                break

        if sess_name:
            subprocess.run(
                [
                    "tmux",
                    "attach-session",
                    "-t",
                    sess_name,
                    ";",
                    "select-pane",
                    "-t",
                    target,
                ]
            )
    else:
        if saved_session:
            subprocess.run(["tmux", "attach-session", "-t", saved_session])


def connect_remote(host, sess):
    if is_in_tmux():
        saved_session = run_cmd(["tmux", "display-message", "-p", "#S"])
        cmd = f"{sys.argv[0]} --connect-remote {shlex.quote(host)} {shlex.quote(sess)} {shlex.quote(saved_session)}"
        run_cmd(["tmux", "detach-client", "-E", cmd])
        sys.exit(0)
    else:
        sys.argv = [sys.argv[0], "--connect-remote", host, sess]
        handle_connect_remote()


def start_or_attach_local(name, path=None):
    safe_name = name.replace(".", "-").replace(":", "-")
    if not run_cmd(["tmux", "has-session", "-t", safe_name]):
        if path:
            subprocess.run(
                [
                    "tmux",
                    "new-session",
                    "-d",
                    "-s",
                    safe_name,
                    "-c",
                    path,
                    "-n",
                    "nvim",
                    "nvim",
                ]
            )
            subprocess.run(["tmux", "new-window", "-c", path, "-t", safe_name])
            subprocess.run(["tmux", "select-window", "-t", f"{safe_name}:nvim"])
        else:
            subprocess.run(["tmux", "new-session", "-d", "-s", safe_name])

    if is_in_tmux():
        subprocess.run(["tmux", "switch-client", "-t", safe_name])
    else:
        subprocess.run(["tmux", "attach", "-t", safe_name])


def handle_preview():
    item = sys.argv[2]
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
        remote_script = f"tmux list-windows -t {shlex.quote(sess)} -F '#I:#W #{{?window_active,(active),}}' && echo && tmux capture-pane -ep -t {shlex.quote(sess)}"
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


def handle_preview_window():
    target = sys.argv[2]
    if target == "[No local windows found]":
        print("No local windows are currently active.")
        return
    if target.startswith("["):
        host, sess_win = target[1:].split("] ", 1)
        print(f"=== Remote Window Preview ({host}) ===")
        remote_script = f"tmux capture-pane -ep -t {shlex.quote(sess_win)}"
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
        out = run_cmd(["tmux", "capture-pane", "-ep", "-t", target])
        print(out)


def handle_dir_preview():
    path = sys.argv[2]
    print("=== Content ===")
    if shutil.which("eza"):
        subprocess.run(
            ["eza", "--tree", "--level=2", "--color=always", "--icons", path]
        )
    else:
        subprocess.run(["ls", "-F", path])


def handle_running():
    while True:
        local_sessions = get_local_sessions()
        all_sessions = local_sessions + ["[Search Remote Sessions]"]

        selected = run_fzf(
            all_sessions, prompt="󰖰  ", preview=f"{sys.argv[0]} --preview {{}}"
        )
        if not selected:
            return

        if selected == "[Search Remote Sessions]":
            print("Fetching remote sessions...")
            remote_sessions = asyncio.run(get_all_remote_sessions())
            if not remote_sessions:
                remote_sessions = ["[No remote sessions found - Back]"]
            selected_remote = run_fzf(
                remote_sessions, prompt="󰖰 (remote)  ", preview=f"{sys.argv[0]} --preview {{}}"
            )
            if not selected_remote or selected_remote.startswith("[No remote sessions found"):
                continue

            if " [" in selected_remote and selected_remote.endswith("]"):
                sess, host = selected_remote.rsplit(" [", 1)
                host = host[:-1]
                connect_remote(host, sess)
                return
        else:
            start_or_attach_local(selected)
            return


def handle_kill():
    while True:
        local_sessions = get_local_sessions()
        all_sessions = local_sessions + ["[Search Remote Sessions]"]

        selected = run_fzf(
            all_sessions, prompt="󰆴  ", preview=f"{sys.argv[0]} --preview {{}}"
        )
        if not selected:
            return

        if selected == "[Search Remote Sessions]":
            print("Fetching remote sessions...")
            remote_sessions = asyncio.run(get_all_remote_sessions())
            if not remote_sessions:
                remote_sessions = ["[No remote sessions found - Back]"]
            selected_remote = run_fzf(
                remote_sessions, prompt="󰆴 (remote)  ", preview=f"{sys.argv[0]} --preview {{}}"
            )
            if not selected_remote or selected_remote.startswith("[No remote sessions found"):
                continue

            if " [" in selected_remote and selected_remote.endswith("]"):
                sess, host = selected_remote.rsplit(" [", 1)
                host = host[:-1]
                # Fast async SSH kill command wrapped in sh -l -c to find the socket
                remote_script = f"tmux kill-session -t {shlex.quote(sess)}"
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
                return
        else:
            subprocess.run(["tmux", "kill-session", "-t", selected])
            return


def handle_new():
    choices = []
    choices.append("[Add New Remote Host]")
    # Add remotes first
    hosts = get_ssh_hosts()
    for h in hosts:
        if h != run_cmd(["hostname"]):
            choices.append(f"[Remote] {h}")

    # Add local dirs
    dirs = []
    for p in SEARCH_PATHS:
        if os.path.isdir(p):
            for entry in os.listdir(p):
                full_path = os.path.join(p, entry)
                if os.path.isdir(full_path):
                    dirs.append(full_path)

    # Add zoxide
    if shutil.which("zoxide"):
        z_dirs = run_cmd(["zoxide", "query", "-l"]).split("\n")
        for z in z_dirs:
            if z and os.path.isdir(z) and z not in dirs:
                dirs.append(z)

    choices.extend(dirs)

    preview_cmd = f'bash -c \'if [[ "$1" == "[Add New Remote Host]" ]]; then echo "Manually add a new remote host to your local state"; elif [[ "$1" == \\[Remote\\]* ]]; then echo "Create new session on remote host"; else "$0" --dir-preview "$1"; fi\' {sys.argv[0]} {{}}'
    selected = run_fzf(choices, prompt="  ", preview=preview_cmd)
    if not selected:
        return

    if selected == "[Add New Remote Host]":
        new_host = input("Enter new hostname or IP: ").strip()
        if new_host:
            state_dir = os.path.expanduser("~/.local/state/tmuxs")
            os.makedirs(state_dir, exist_ok=True)
            with open(os.path.join(state_dir, "hosts.txt"), "a") as f:
                f.write(new_host + "\n")
            print(f"Added {new_host} to saved hosts!")
            sess_name = input("Session name (default 'main'): ").strip()
            if not sess_name:
                sess_name = "main"
            connect_remote(new_host, sess_name)
        return

    if selected.startswith("[Remote] "):
        host = selected.split(" ", 1)[1]
        print(f"Creating new session on {host}")
        sess_name = input("Session name (default 'main'): ").strip()
        if not sess_name:
            sess_name = "main"
        connect_remote(host, sess_name)
    else:
        basename = os.path.basename(selected)
        start_or_attach_local(basename, selected)


def handle_windows():
    # List all panes across all local sessions
    format_str = "#{session_name}:#{window_index}\t#{session_name}  ➜  #{window_name}  #{?#{==:#{pane_current_command},fish},,[#{pane_current_command}]}"
    out = run_cmd(["tmux", "list-panes", "-a", "-F", format_str])
    choices = out.split("\n") if out else []

    if not choices:
        choices = ["[No local windows found]"]

    selected = run_fzf(
        choices,
        prompt="󰖲  ",
        preview=f"{sys.argv[0]} --preview-window {{1}}",
        extra_args=["--delimiter=\t", "--with-nth=2"],
    )
    if not selected or selected == "[No local windows found]":
        return

    target = selected.split("\t")[0]
    run_cmd(["tmux", "switch-client", "-t", target])


def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "--preview":
            handle_preview()
            sys.exit(0)
        elif sys.argv[1] == "--preview-window":
            handle_preview_window()
            sys.exit(0)
        elif sys.argv[1] == "--dir-preview":
            handle_dir_preview()
            sys.exit(0)
        elif sys.argv[1] == "--windows":
            handle_windows()
            sys.exit(0)
        elif sys.argv[1] == "running-sessions":
            handle_running()
            sys.exit(0)
        elif sys.argv[1] == "--connect-remote":
            handle_connect_remote()
            sys.exit(0)
        else:
            # Handle direct session/dir launch (e.g. `tmuxs nixos-config`)
            arg = sys.argv[1]
            found_path = None

            if arg == ".":
                found_path = os.getcwd()
                arg = os.path.basename(found_path) or "root"
            else:
                for p in SEARCH_PATHS:
                    full_path = os.path.join(p, arg)
                    if os.path.isdir(full_path):
                        found_path = full_path
                        break

            if found_path:
                start_or_attach_local(arg, found_path)
            else:
                # Fallback to pure session name
                start_or_attach_local(arg)
            sys.exit(0)

    has_sessions = bool(get_local_sessions())
    options = ["new-session"]
    if has_sessions:
        options = ["new-session", "running-sessions", "kill-session"]

    selected = run_fzf(options, prompt="  ")
    if selected == "running-sessions":
        handle_running()
    elif selected == "kill-session":
        handle_kill()
    elif selected == "new-session":
        handle_new()


if __name__ == "__main__":
    main()

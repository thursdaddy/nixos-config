import argparse
import os
import re
import socket

import docker
import requests


def convert_to_api_url(repo_url, container_name):
    """Convert a GitHub repository URL to an API URL for querying the latest release or tags"""
    if "github.com" in repo_url:
        if repo_url == "https://github.com/gitlabhq/gitlabhq":
            return "https://api.github.com/repos/gitlabhq/gitlabhq/tags"
        else:
            api_url = repo_url.replace("github.com", "api.github.com/repos")
            if container_name == "gitlab":
                api_url = f"{api_url}/tags"
            else:
                api_url = f"{api_url}/releases/latest"
            return api_url
    return None


def get_latest_release(api_url, container_name, repo_url):
    """Query the API to get the latest release or tag"""
    headers = {}
    token_path = "/run/secrets/github/TOKEN"
    if os.path.exists(token_path):
        try:
            with open(token_path, "r") as f:
                content = f.read().strip()
                match = re.search(r"github\.com=(github_pat_\S+)$", content)
            if match:
                headers["Authorization"] = f"token {match.group(1)}"
        except Exception as e:
            print(f"Warning: Could not read GitHub token: {e}")

    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()

        if isinstance(data, dict) and "tag_name" in data:
            return data["tag_name"]
        elif isinstance(data, list) and len(data) > 0 and "name" in data[0]:
            version_tags = [
                item.get("name")
                for item in data
                if item.get("name")
                and re.match(r"^(v)?\d+(\.\d+){0,2}([\-.]\S+)?$", item.get("name"))
            ]
            if version_tags:

                def version_key(tag):
                    parts = re.split(r"[\.-]", normalize_version(tag))
                    return [int(p) if p.isdigit() else p for p in parts]

                version_tags.sort(key=version_key, reverse=True)
                return (
                    version_tags[1]
                    if repo_url == "https://github.com/gitlabhq/gitlabhq"
                    and len(version_tags) > 1
                    else version_tags[0]
                )
        return None
    except requests.RequestException as e:
        print(f"Error fetching latest release from {api_url}: {e}")
        return None


def normalize_version(version):
    return re.sub(r"^v", "", version)


def send_to_gotify(title, message):
    """Send a notification to Gotify with Markdown support"""
    base_url = os.getenv("GOTIFY_URL")
    token = os.getenv("GOTIFY_APP_TOKEN")

    if not base_url or not token:
        print("Missing GOTIFY_URL or GOTIFY_APP_TOKEN environment variables.")
        return

    url = f"{base_url.rstrip('/')}/message?token={token}"

    # Re-enabled markdown extras so links will be clickable.
    # Line breaks are handled by adding two spaces at the end of lines in the main function.
    payload = {
        "title": title,
        "message": message,
        "priority": 5,
        "extras": {
            "client::display": {
                "contentType": "text/markdown"
            }
        }
    }

    try:
        requests.post(url, json=payload).raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to send to Gotify: {e}")


def get_hostname():
    return socket.gethostname()


def main(gotify_flag):
    hostname = get_hostname()
    up_to_date, outdated, missing_labels = [], [], []
    gotify_lines = []

    try:
        client = docker.from_env()
        containers = client.containers.list()
    except Exception as e:
        error_msg = f"Error connecting to Docker: {e}"
        print(error_msg)
        if gotify_flag:
            send_to_gotify(f"Docker Error: {hostname}", error_msg)
        return

    if not containers:
        return

    for container in containers:
        # Skip containers with specific prefixes
        if container.name.startswith("GITEA-ACTION") or container.name.startswith("buildx_buildkit"):
            continue

        labels = container.labels
        if labels.get("enable.versions.check") == "false":
            continue

        repo_url = labels.get("org.opencontainers.image.source")
        current_v_label = labels.get("org.opencontainers.image.version")

        if not repo_url or not current_v_label:
            missing_labels.append(container.name)
            continue

        api_url = convert_to_api_url(repo_url, container.name)
        latest_tag = (
            get_latest_release(api_url, container.name, repo_url) if api_url else None
        )

        if not latest_tag:
            continue

        current_v = normalize_version(current_v_label)
        latest_v = normalize_version(latest_tag)

        if current_v == latest_v:
            up_to_date.append(f"{container.name:<20} {current_v}")
        else:
            # Build the release notes link
            release_url = f"{repo_url}/releases/tag/{latest_tag}"

            # Print to console with URL
            outdated.append(f"{container.name:<20} {current_v} -> {latest_v} ({release_url})")

            # Markdown link format for Gotify: [link text](URL)
            gotify_lines.append(f"📦 {container.name}: {current_v} -> [{latest_v}]({release_url})")

    # Print to console
    print(f"Hostname: {hostname}\n" + "=" * 40)
    for title, log in [
        ("✅ Up-to-date", up_to_date),
        ("⏩ Outdated", outdated),
        ("❌ Missing Labels", missing_labels),
    ]:
        print(f"\n{title}:")
        print("-" * 40)
        for line in log:
            print(line)

    # Send to Gotify
    if gotify_flag and (gotify_lines or missing_labels):
        msg_parts = []

        if gotify_lines:
            msg_parts.append("**Outdated Containers:**")
            msg_parts.extend(gotify_lines)

        if missing_labels:
            if msg_parts:
                msg_parts.append("")  # Spacer line
            msg_parts.append("**Missing Labels:**")
            msg_parts.extend([f"⚠️ {name}" for name in missing_labels])

        # Joining with two spaces and a newline ("  \n") to force standard Markdown line-breaks
        full_message = "  \n".join(msg_parts)
        send_to_gotify(f"Updates Available: {hostname}", full_message)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--gotify", action="store_true")
    args = parser.parse_args()
    main(args.gotify)

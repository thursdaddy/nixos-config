#!@py@

import argparse
import json
import os
import re
import socket
import subprocess

import requests


def run_command(cmd):
    """Run a shell command and return the output"""
    result = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.returncode != 0:
        print(f"Error running command {' '.join(cmd)}: {result.stderr}")
        return None
    return result.stdout.strip()


def get_containers():
    """Get a list of running container IDs and names"""
    output = run_command(["docker", "ps", "--format", "{{.ID}} {{.Names}}"])
    if not output:
        return []

    containers = [line.split() for line in output.splitlines()]
    return containers


def get_label_value(container_id, label):
    """Get the value of a specific label from docker inspect"""
    output = run_command(["docker", "inspect", container_id])
    if not output:
        return None

    inspect_data = json.loads(output)
    try:
        return inspect_data[0]["Config"]["Labels"].get(label, None)
    except (KeyError, IndexError):
        return None


def convert_to_api_url(repo_url, container_name):
    """Convert a GitHub repository URL to an API URL for querying the latest release or tags"""
    if "github.com" in repo_url:
        api_url = repo_url.replace("github.com", "api.github.com/repos")
        if container_name == "gitlab":  # Check if container is GitLab
            api_url = f"{api_url}/tags"
        else:
            api_url = f"{api_url}/releases/latest"
        return api_url
    else:
        return None


def get_latest_release(api_url):
    """Query the API to get the latest release or tag"""
    headers = {}

    # Read GitHub token if available
    token_path = "/run/secrets/github/TOKEN"
    if os.path.exists(token_path):
        with open(token_path, "r") as f:
            content = f.read().strip()
            # Extract the GitHub PAT using regex
            match = re.search(r"github\.com=(github_pat_\S+)$", content)
        if match:
            token = match.group(1)
            headers["Authorization"] = f"token {token}"
        else:
            print("GitHub PAT not found in the expected format")

    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()

        # Check if this is a GitHub release API response
        if isinstance(data, dict) and "tag_name" in data:  # GitHub
            return data["tag_name"]

        # Check if this is a GitLab tag list response
        elif isinstance(data, list) and len(data) > 0 and "name" in data[0]:  # GitLab
            return data[0]["name"]

        else:
            print(f"Unexpected API response format: {data}")
            return None

    except requests.RequestException as e:
        print(f"Error fetching latest release from {api_url}: {e}")
        return None


def normalize_version(version):
    """Strip leading 'v' from version strings and return the normalized version"""
    return re.sub(r"^v", "", version)


def send_to_discord(embed_data):
    """Send the message to a Discord webhook"""
    webhook_url = os.getenv("DISCORD_WEBHOOK_URL")
    if not webhook_url:
        print(
            "No Discord webhook URL found in environment variable DISCORD_WEBHOOK_URL."
        )
        return

    data = {"embeds": embed_data}

    try:
        response = requests.post(webhook_url, json=data)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to send message to Discord: {e}")


def get_hostname():
    """Get the system's hostname"""
    return socket.gethostname()


def main(discord_flag):
    containers = get_containers()

    if not containers:
        print("No running containers found.")
        return

    # Get the system's hostname
    hostname = get_hostname()

    # Print hostname to stdout
    print(f"Hostname: {hostname}")
    print("=" * 40)  # Separator line for better clarity

    up_to_date_containers = []
    outdated_containers = []
    missing_label_containers = []

    discord_up_to_date_containers = []
    discord_outdated_containers = []

    for container_id, container_name in containers:
        # Get the repository URL from the label
        repo_url = get_label_value(container_id, "org.opencontainers.image.source")

        # Check if the container is enabled for version checking
        enable_version_check = get_label_value(container_id, "enable.versions.check")
        if enable_version_check == "false":
            continue  # Skip this container if version check is disabled

        if not repo_url:
            # Add to missing labels list
            missing_label_containers.append(container_name)
            continue

        # Get the latest release tag
        api_url = convert_to_api_url(repo_url, container_name)
        if not api_url:
            continue

        latest_release_tag = get_latest_release(api_url)
        if not latest_release_tag:
            continue

        latest_release_version = normalize_version(latest_release_tag)

        # Get the running container's version from the label
        container_version_label = get_label_value(
            container_id, "org.opencontainers.image.version"
        )
        if not container_version_label:
            missing_label_containers.append(container_name)
            continue

        container_version = normalize_version(container_version_label)

        # Check if the container is up-to-date or outdated
        if container_version == latest_release_version:
            # Add to stdout list
            up_to_date_containers.append(f"{container_name:<20} {container_version}")
            # Add to Discord embed list
            discord_up_to_date_containers.append(
                f"{container_name}: _{container_version}_"
            )
        else:
            # Add to stdout list for outdated containers
            outdated_containers.append(
                f"{container_name:<20} {container_version}  ->  {latest_release_version}"
            )
            outdated_containers.append(f"  Latest release: {repo_url}/releases/latest")
            # Add to Discord embed list for outdated containers
            discord_outdated_containers.append(
                f"{container_name}: _{container_version}_ -> **[{latest_release_version}]({repo_url}/releases/latest)**"
            )

    # Print stdout results
    print("\n✅  Up-to-date Containers:")
    print("-" * 40)
    if up_to_date_containers:
        for line in up_to_date_containers:
            print(line)
    else:
        print("No up-to-date containers.")

    print("\n⏩  Outdated Containers:")
    print("-" * 40)
    if outdated_containers:
        for line in outdated_containers:
            print(line)
    else:
        print("No outdated containers.")

    # Print missing labels
    print("\n❌  Containers Missing Labels:")
    print("-" * 40)
    if missing_label_containers:
        for line in missing_label_containers:
            print(line)
    else:
        print("No containers missing labels.")

    # Only send to Discord if the flag is passed
    if discord_flag:
        # Create Discord embed message
        embed_data = [
            {
                "title": "Container Version Status",
                "description": f"**Hostname:** {hostname}",
                "color": 3066993,  # Green color for embed
                "fields": [],
            }
        ]

        if discord_up_to_date_containers:
            embed_data[0]["fields"].append(
                {
                    "name": "✅ Up-to-date Containers",
                    "value": "\n".join(discord_up_to_date_containers),
                    "inline": False,
                }
            )

        if discord_outdated_containers:
            embed_data[0]["fields"].append(
                {
                    "name": "⏩ Outdated Containers",
                    "value": "\n".join(discord_outdated_containers),
                    "inline": False,
                }
            )

        if missing_label_containers:
            embed_data[0]["fields"].append(
                {
                    "name": "❌ Missing Labels",
                    "value": "\n".join(
                        [f"{name}" for name in missing_label_containers]
                    ),
                    "inline": False,
                }
            )

        # Send message to Discord if there are any relevant containers
        if (
            discord_up_to_date_containers
            or discord_outdated_containers
            or missing_label_containers
        ):
            send_to_discord(embed_data)


if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description="Check container versions and optionally send to Discord."
    )
    parser.add_argument(
        "--discord", action="store_true", help="Send results to Discord"
    )

    args = parser.parse_args()

    # Pass the flag to the main function
    main(discord_flag=args.discord)

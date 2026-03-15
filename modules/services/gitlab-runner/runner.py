import argparse
import logging
import os
import sys

import requests

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

GITLAB_URL = os.getenv("GITLAB_URL")
GITLAB_ACCESS_TOKEN = os.getenv("GITLAB_ACCESS_TOKEN")
GITLAB_RUNNER_CONFIG_PATH = os.getenv("GITLAB_RUNNER_CONFIG_PATH")

HEADERS = {"Private-Token": GITLAB_ACCESS_TOKEN}
API_BASE_URL = f"{GITLAB_URL}/api/v4"

if not all([GITLAB_URL, GITLAB_ACCESS_TOKEN, GITLAB_RUNNER_CONFIG_PATH]):
    logging.error("Error: One or more required environment variables are not set.")
    logging.error(
        "Please set GITLAB_URL, GITLAB_ACCESS_TOKEN, and GITLAB_RUNNER_CONFIG_PATH."
    )
    sys.exit(1)

def is_gitlab_up():
    """
    Checks if the GitLab instance is reachable.
    Fails gracefully if the server is down.
    """
    logging.info(f"Checking if GitLab is reachable at {GITLAB_URL}...")
    try:
        # We use a short timeout so the script doesn't hang indefinitely
        # /api/v4/version is a reliable way to check if the API is actually responding
        response = requests.get(f"{API_BASE_URL}/version", headers=HEADERS, timeout=5)
        response.raise_for_status()
        logging.info("GitLab is up and running.")
        return True
    except requests.exceptions.RequestException as e:
        logging.warning(f"GitLab is unreachable or down: {e}")
        return False

def check_existing_runners(tags: str):
    """
    Checks if any runners with the specified tags already exist.
    """
    endpoint = f"{API_BASE_URL}/runners/all"
    params = {"tag_list": tags}

    logging.info(f"Checking for existing runners with tags: [{tags}]")
    try:
        response = requests.get(endpoint, headers=HEADERS, params=params, timeout=10)
        response.raise_for_status()
        runners = response.json()
        if runners:
            logging.info(f"Found {len(runners)} existing runner(s) with tags '{tags}'.")
            return True
        logging.info(f"No existing runners found with tags '{tags}'.")
        return False
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to check for existing runners: {e}")
        sys.exit(1)

def register_runner(tags: str, name: str):
    """
    Registers a new GitLab runner and creates a config file.
    """
    if not is_gitlab_up():
        logging.error("Skipping registration: GitLab instance is offline.")
        # Exit 0 if you want the calling service (like systemd) to think "it's fine"
        # Exit 1 if you want the service to show as "failed"
        sys.exit(0)

    if check_existing_runners(tags):
        logging.info("Exiting registration as existing runners were found.")
        return

    endpoint = f"{API_BASE_URL}/user/runners"
    payload = {
        "runner_type": "instance_type",
        "tag_list": tags,
    }

    logging.info(f"Attempting to register a new runner with tags: [{tags}]")
    try:
        response = requests.post(endpoint, headers=HEADERS, json=payload, timeout=10)
        response.raise_for_status()

        data = response.json()
        runner_token = data.get("token")
        if not runner_token:
            logging.error("Failed to retrieve runner token from API response.")
            sys.exit(1)

        file_path = f"{GITLAB_RUNNER_CONFIG_PATH}/{name}"
        with open(file_path, "w") as f:
            f.write(f"CI_SERVER_URL={GITLAB_URL}\n")
            f.write(f"CI_SERVER_TOKEN={runner_token}\n")

        logging.info("Runner registration process completed successfully.")

    except requests.exceptions.RequestException as e:
        logging.error(f"API request failed: {e}")
        sys.exit(1)
    except IOError as e:
        logging.error(f"Failed to write to file {file_path}: {e}")
        sys.exit(1)

def deregister_runner(tags: str):
    """
    Finds all runners matching the tags and deletes them.
    """
    if not is_gitlab_up():
        logging.error("Skipping de-registration: GitLab instance is offline.")
        sys.exit(0)

    endpoint = f"{API_BASE_URL}/runners/all"
    params = {"tag_list": tags}

    try:
        response = requests.get(endpoint, headers=HEADERS, params=params, timeout=10)
        response.raise_for_status()
        runners = response.json()

        if not runners:
            logging.warning(f"No runners found with tags '{tags}'.")
            return

        for runner in runners:
            runner_id = runner.get("id")
            delete_endpoint = f"{API_BASE_URL}/runners/{runner_id}"
            delete_response = requests.delete(delete_endpoint, headers=HEADERS, timeout=10)
            delete_response.raise_for_status()
            logging.info(f"Successfully de-registered runner ID: {runner_id}.")

    except requests.exceptions.RequestException as e:
        logging.error(f"API request failed: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Manage GitLab runners via API.")
    parser.add_argument("--tags", type=str, required=True)
    parser.add_argument("--name", type=str, required=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--register", action="store_true")
    group.add_argument("--de-register", action="store_true")

    args = parser.parse_args()

    if args.register:
        register_runner(args.tags, args.name)
    elif args.de_register:
        deregister_runner(args.tags)

if __name__ == "__main__":
    main()

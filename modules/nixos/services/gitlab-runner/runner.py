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


def check_existing_runners(tags: str):
    """
    Checks if any runners with the specified tags already exist.
    Returns True if runners are found, False otherwise.
    """
    endpoint = f"{API_BASE_URL}/runners/all"
    params = {"tag_list": tags}

    logging.info(f"Checking for existing runners with tags: [{tags}]")
    try:
        response = requests.get(endpoint, headers=HEADERS, params=params)
        response.raise_for_status()
        runners = response.json()
        if runners:
            logging.info(f"Found {len(runners)} existing runner(s) with tags '{tags}'.")
            return True
        logging.info(f"No existing runners found with tags '{tags}'.")
        return False
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to check for existing runners: {e}")
        if e.response is not None:
            logging.error(f"Response Body: {e.response.text}")
        sys.exit(1)


def register_runner(tags: str, name: str):
    """
    Registers a new GitLab runner using the user API endpoint and creates
    a temporary file with its registration token. This file is used by the
    NixOS module:
    services.gitlab-runner.<name>.authenticationTokenConfigFile
    """
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
        # Make the API call to create the runner
        response = requests.post(endpoint, headers=HEADERS, json=payload)
        response.raise_for_status()  # Raises HTTPError

        data = response.json()
        runner_token = data.get("token")
        if not runner_token:
            logging.error("Failed to retrieve runner token from API response.")
            sys.exit(1)

        logging.info(
            f"Successfully created runner registration token. Runner ID: {data.get('id')}"
        )

        # Create the registration file, overwriting if it exists
        file_path = f"{GITLAB_RUNNER_CONFIG_PATH}/{name}"

        logging.info(f"Writing registration details to {file_path}")
        with open(file_path, "w") as f:
            f.write(f"CI_SERVER_URL={GITLAB_URL}\n")
            f.write(f"CI_SERVER_TOKEN={runner_token}\n")

        logging.info("Runner registration process completed successfully.")

    except requests.exceptions.RequestException as e:
        logging.error(f"API request failed: {e}")
        if e.response is not None:
            logging.error(f"Response Body: {e.response.text}")
        sys.exit(1)
    except IOError as e:
        logging.error(f"Failed to write to file {file_path}: {e}")
        sys.exit(1)


# -----------------------------------------------------------------------------
# Runner deregistration
# -----------------------------------------------------------------------------


def deregister_runner(tags: str):
    """
    Finds all runners matching the tags and deletes them.
    """
    endpoint = f"{API_BASE_URL}/runners/all"
    params = {"tag_list": tags}

    logging.info(f"Searching for runners with tags: [{tags}]")
    try:
        # Find the runner(s) by tags
        response = requests.get(endpoint, headers=HEADERS, params=params)
        response.raise_for_status()

        runners = response.json()

        if not runners:
            logging.warning(f"No runners found with tags '{tags}'.")
            return

        # Iterate and delete each found runner
        for runner in runners:
            runner_id = runner.get("id")
            runner_desc = runner.get("description", f"ID: {runner_id}")

            logging.info(f"Found runner '{runner_desc}'. Attempting to de-register...")
            delete_endpoint = f"{API_BASE_URL}/runners/{runner_id}"

            delete_response = requests.delete(delete_endpoint, headers=HEADERS)

            # GitLab API returns 204 No Content on successful deletion
            if delete_response.status_code == 204:
                logging.info(
                    f"Successfully de-registered runner '{runner_desc}' (ID: {runner_id})."
                )
            else:
                # Let raise_for_status handle non-204 errors for consistency
                delete_response.raise_for_status()

    except requests.exceptions.RequestException as e:
        logging.error(f"API request failed: {e}")
        if e.response is not None:
            logging.error(f"Response Body: {e.response.text}")
        sys.exit(1)


# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------


def main():
    """
    Parses command-line arguments and executes the corresponding action.
    """
    parser = argparse.ArgumentParser(
        description="A script to manage GitLab runners via the API.",
        epilog="Ensure GITLAB_URL and GITLAB_ACCESS_TOKEN are set as environment variables.",
    )
    parser.add_argument(
        "--tags",
        type=str,
        required=True,
        help="Comma-separated list of tags for the runner.",
    )
    parser.add_argument(
        "--name",
        type=str,
        required=True,
        help="The name of the runner config file.",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--register",
        action="store_true",
        help="Register a new runner and create a token file.",
    )
    group.add_argument(
        "--de-register",
        action="store_true",
        help="Find and de-register existing runners by tags.",
    )

    args = parser.parse_args()

    if args.register:
        register_runner(args.tags, args.name)
        sys.exit(0)
    elif args.de_register:
        deregister_runner(args.tags)


if __name__ == "__main__":
    main()

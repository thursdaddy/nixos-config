import logging
import os
import sys

import requests
from google.cloud import dns
from google.api_core.exceptions import GoogleAPIError

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

DOMAINS_ENV = os.environ.get("DOMAINS")
GOTIFY_URL = os.environ.get("GOTIFY_URL")
GOTIFY_TOKEN = os.environ.get("GOTIFY_APP_TOKEN")
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID")

cred_dir = os.environ.get("CREDENTIALS_DIRECTORY")
if cred_dir and not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.join(cred_dir, "CREDENTIALS.JSON")

if not all([DOMAINS_ENV, GOTIFY_URL, GOTIFY_TOKEN, GCP_PROJECT_ID]):
    logger.error(
        "Missing required environment variables. Ensure DOMAINS, GOTIFY_URL, GOTIFY_APP_TOKEN, and GCP_PROJECT_ID are set."
    )
    sys.exit(1)

DOMAINS = [d.strip() for d in DOMAINS_ENV.split(",") if d.strip()]


def get_public_ip():
    """Fetches the current public IP address."""
    try:
        response = requests.get("https://api.ipify.org?format=json", timeout=10)
        response.raise_for_status()
        return response.json().get("ip")
    except requests.RequestException as e:
        logger.error(f"Failed to fetch public IP: {e}")
        return None


def send_gotify_notification(title, message, priority=5):
    """Sends a push notification via Gotify."""
    url = f"{GOTIFY_URL.rstrip('/')}/message"
    headers = {"X-Gotify-Key": GOTIFY_TOKEN}
    data = {"title": title, "message": message, "priority": priority}
    try:
        response = requests.post(url, headers=headers, json=data, timeout=10)
        response.raise_for_status()
        logger.info("Gotify notification sent successfully.")
    except requests.RequestException as e:
        logger.error(f"Failed to send Gotify notification: {e}")


def get_hosted_zone(client, domain):
    """Finds the correct GCP Managed Zone for a given domain."""
    try:
        for zone in client.list_zones():
            if domain.endswith(zone.dns_name.rstrip(".")):
                return zone
        logger.error(f"Could not find a Managed Zone matching domain: {domain}")
        return None
    except GoogleAPIError as e:
        logger.error(f"GCP API Error looking up Managed Zones: {e}")
        return None


def get_current_record(zone, domain):
    """Fetches the current A record registered in GCP for the domain."""
    try:
        for record in zone.list_resource_record_sets():
            if record.name.rstrip(".") == domain and record.record_type == "A":
                return record
        return None
    except GoogleAPIError as e:
        logger.error(f"GCP API Error looking up DNS record for {domain}: {e}")
        return None


def update_dns_record(zone, domain, new_ip, old_record):
    """Updates the GCP A record with the new IP."""
    try:
        changes = zone.changes()
        if old_record:
            changes.delete_record_set(old_record)
        
        new_record = zone.resource_record_set(
            domain + ".", "A", 300, [new_ip]
        )
        changes.add_record_set(new_record)
        changes.create()
        return True
    except GoogleAPIError as e:
        logger.error(f"GCP API Error updating DNS record for {domain}: {e}")
        return False


def main():
    current_ip = get_public_ip()
    if not current_ip:
        sys.exit(1)

    logger.info(f"Current public IP is: {current_ip}")

    dns_client = dns.Client(project=GCP_PROJECT_ID)
    updates_made = []
    errors_encountered = []

    for domain in DOMAINS:
        logger.info(f"Checking domain: {domain}")

        zone = get_hosted_zone(dns_client, domain)
        if not zone:
            errors_encountered.append(f"{domain}: Failed to find Managed Zone.")
            continue

        old_record = get_current_record(zone, domain)
        dns_ip = old_record.rrdatas[0] if old_record and old_record.rrdatas else None

        if dns_ip == current_ip:
            logger.info(f"[{domain}] IP matches ({current_ip}). No update needed.")
            continue

        logger.info(
            f"[{domain}] IP mismatch! DNS: {dns_ip} -> Current: {current_ip}. Updating..."
        )

        success = update_dns_record(zone, domain, current_ip, old_record)

        if success:
            logger.info(f"[{domain}] Successfully updated GCP Cloud DNS.")
            updates_made.append(f"✅ {domain}: {dns_ip} -> {current_ip}")
        else:
            errors_encountered.append(f"❌ {domain}: Update failed.")

    if updates_made or errors_encountered:
        title = "DDNS Update Report"
        message_lines = []

        if updates_made:
            message_lines.append("Successful Updates:")
            message_lines.extend(updates_made)

        if errors_encountered:
            message_lines.append("\nErrors:")
            message_lines.extend(errors_encountered)

        send_gotify_notification(title, "\n".join(message_lines))


if __name__ == "__main__":
    main()

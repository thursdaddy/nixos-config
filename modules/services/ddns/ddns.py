import logging
import os
import sys

import boto3
import requests
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Load Environment Variables
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION
DOMAINS_ENV = os.environ.get("DOMAINS")
GOTIFY_URL = os.environ.get("GOTIFY_URL")
GOTIFY_TOKEN = os.environ.get("GOTIFY_APP_TOKEN")

if not all([DOMAINS_ENV, GOTIFY_URL, GOTIFY_TOKEN]):
    logger.error(
        "Missing required environment variables. Ensure DOMAINS, GOTIFY_URL, and GOTIFY_APP_TOKEN are set."
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


def get_hosted_zone_id(client, domain):
    """Finds the correct Route53 Hosted Zone ID for a given domain."""
    try:
        # Route53 zones end with a dot (e.g., "test.net.")
        paginator = client.get_paginator("list_hosted_zones")
        for page in paginator.paginate():
            for zone in page["HostedZones"]:
                if domain.endswith(zone["Name"].rstrip(".")):
                    return zone["Id"]
        logger.error(f"Could not find a Hosted Zone matching domain: {domain}")
        return None
    except ClientError as e:
        logger.error(f"AWS API Error looking up Hosted Zones: {e}")
        return None


def get_current_dns_ip(client, zone_id, domain):
    """Fetches the current IP address registered in Route53 for the domain."""
    try:
        response = client.list_resource_record_sets(
            HostedZoneId=zone_id,
            StartRecordName=domain,
            StartRecordType="A",
            MaxItems="1",
        )
        records = response.get("ResourceRecordSets", [])
        if (
            records
            and records[0]["Name"].rstrip(".") == domain
            and records[0]["Type"] == "A"
        ):
            return records[0]["ResourceRecords"][0]["Value"]
        return None
    except ClientError as e:
        logger.error(f"AWS API Error looking up DNS record for {domain}: {e}")
        return None


def update_dns_record(client, zone_id, domain, new_ip):
    """Updates the Route53 A record with the new IP."""
    try:
        response = client.change_resource_record_sets(
            HostedZoneId=zone_id,
            ChangeBatch={
                "Comment": "Automated DDNS update",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": domain,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": new_ip}],
                        },
                    }
                ],
            },
        )
        return True
    except ClientError as e:
        logger.error(f"AWS API Error updating DNS record for {domain}: {e}")
        return False


def main():
    current_ip = get_public_ip()
    if not current_ip:
        sys.exit(1)

    logger.info(f"Current public IP is: {current_ip}")

    r53_client = boto3.client("route53")
    updates_made = []
    errors_encountered = []

    for domain in DOMAINS:
        logger.info(f"Checking domain: {domain}")

        zone_id = get_hosted_zone_id(r53_client, domain)
        if not zone_id:
            errors_encountered.append(f"{domain}: Failed to find Hosted Zone.")
            continue

        dns_ip = get_current_dns_ip(r53_client, zone_id, domain)

        if dns_ip == current_ip:
            logger.info(f"[{domain}] IP matches ({current_ip}). No update needed.")
            continue

        logger.info(
            f"[{domain}] IP mismatch! DNS: {dns_ip} -> Current: {current_ip}. Updating..."
        )

        success = update_dns_record(r53_client, zone_id, domain, current_ip)

        if success:
            logger.info(f"[{domain}] Successfully updated Route53.")
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

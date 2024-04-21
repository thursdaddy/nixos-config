# Route53 Updater

# Purpose

AWS started charging for EIP, so this is an easy alternative for my basic use case. It runs during boot via systemd once network connectivity is established.

# Requirements

As this runs aws commands, credentials are required. This can be done with an instance profile, or exporting env variables.

IAM access, needs access to route53 to query for hosted zone records and update zone records.

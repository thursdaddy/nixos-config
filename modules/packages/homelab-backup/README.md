# Homelab Backup

A Python script for idempotent backups of Docker containers mounts and local directories. It handles change detection via SHA-256, retention logic, and outputs structured logs for Grafana/Loki integration.

---

## Features

* **Idempotence:** Saves a new archive only if files have changed since the last run.
* **Docker Integration:** Automatically pulls configuration from container labels.
* **Reproducible Archives:** Uses fixed timestamps and sorted filenames to ensure consistent hashes for identical data.
* **JSON Logging:** Optional structured logging for Alloy, Loki, or ELK stacks.
* **Dry Run Mode:** Preview actions without modifying the filesystem.

---

## Configuration & Resolution Logic

The `--type` argument is optional. The script determines the backup source and configuration using a specific hierarchy:

1.  **Check for Container:** The script attempts to find a Docker container matching the `--name`.
2.  **Label Priority:** If a container is found, it checks for `homelab.backup.*` labels. These values override any host-level environment variables for that specific target.
3.  **Env Var Fallback:** If labels are missing, or if no container is found, it converts the configuration key to an uppercase environment variable (e.g., `HOMELAB_BACKUP_PATH`).
4.  **Implicit Type Detection:** * If `HOMELAB_BACKUP_ENABLE` is set in the environment, it defaults to `path`.
    * Otherwise, it defaults to `docker`.

### Docker Labels
Applied directly to the target container.

| Label | Description | Default |
| :--- | :--- | :--- |
| homelab.backup.enable | Must be "true" to allow backups. | false |
| homelab.backup.base.dest | Override the root storage directory for this target. | `/mnt/backups` |
| homelab.backup.path | The source directory (on the host) to be archived. | None |
| homelab.backup.retention.period | Number of historical archives to keep. | 5 |
| homelab.backup.path.ignore | Comma-separated list of paths to exclude. | "" |
| homelab.backup.path.include | Comma-separated list of extra paths to include. | "" |

### Environment Variables
Global system settings and fallbacks for path-based backups.

| Variable | Description | Default |
| :--- | :--- | :--- |
| HOMELAB_BACKUP_ENABLE | Master toggle for path-based backups. | false |
| HOMELAB_BACKUP_BASE_DEST | **Global:** Destination directory for all archives. | `/mnt/backups` |
| HOMELAB_BACKUP_PATH | Source directory for path-based backups. | None |
| HOMELAB_BACKUP_RETENTION_PERIOD | Retention count fallback. | 5 |
| HOMELAB_BACKUP_PATH_IGNORE | Exclude list fallback. | "" |
| HOMELAB_BACKUP_PATH_INCLUDE | Include list fallback. | "" |

---

## Usage

### CLI Arguments

| Argument | Requirement | Description |
| :--- | :--- | :--- |
| `--name` | **Required** | The name of the Docker container or the unique ID for the backup target. |
| `--backup` | Optional | Executes the archive/compression process for the target. |
| `--rotate` | Optional | Cleans up old archives based on the defined retention period. |
| `--type` | Optional | Explicitly sets the mode to `docker` or `path`. Usually inferred. |
| `--json` | Optional | Enables structured JSON log output for Loki/Alloy. |
| `--dry-run` | Optional | Logs intended actions without modifying the filesystem. |
### Examples

**Automatic (Inferred) Backup:**
If `my-container` exists with labels, this automatically runs a Docker backup and saves it to `/mnt/backups/docker/my-container/`:
```bash
python backup.py --name my-container --backup
```

**Explicit Path Backup:**
```export HOMELAB_BACKUP_ENABLE=true
export HOMELAB_BACKUP_PATH=/home/user/notes
python backup.py --name obsidian --type path --backup
```

**Rotate backups:**
```
python backup.py --name obsidian --type path --rotate
```

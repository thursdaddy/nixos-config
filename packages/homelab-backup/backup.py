# flake8: noqa: E501
import argparse
import hashlib
import json
import logging
import os
import subprocess
import sys
import time
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import docker


class BackupError(Exception):
    """Custom exception for backup-related failures."""

    pass


class JsonFormatter(logging.Formatter):
    """Custom formatter to output logs as JSON for Alloy/Loki/Grafana"""

    def format(self, record: logging.LogRecord) -> str:
        log_record = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
        }

        if record.args:
            if isinstance(record.args, dict):
                log_record.update(record.args)
            elif (
                isinstance(record.args, tuple)
                and len(record.args) == 1
                and isinstance(record.args[0], dict)
            ):
                log_record.update(record.args[0])

        return json.dumps(log_record)


class BackupManager:
    def __init__(self, dry_run: bool = False, json_logs: bool = False):
        self.dry_run = dry_run
        self.json_logs = json_logs
        self.logger = self._setup_logging()
        self.client = None

        uid = os.getuid()

        # Prioritize Rootless Podman -> Rootful Podman -> Standard Docker
        socket_paths = [
            f"unix:///run/user/{uid}/podman/podman.sock",
            "unix:///run/podman/podman.sock",
            "unix:///var/run/docker.sock",
        ]

        for sock in socket_paths:
            try:
                self.client = docker.DockerClient(base_url=sock)
                self.client.ping()
                # Optional: self.logger.debug(f"Connected to container engine via {sock}")
                break
            except Exception:
                self.client = None

        # Ultimate fallback: check environment variables (e.g., DOCKER_HOST)
        if not self.client:
            try:
                self.client = docker.from_env()
                self.client.ping()
            except Exception:
                self.client = None

        if not self.client:
            self.logger.debug(
                "Container socket not reachable; engine-specific features disabled."
            )

        self.global_base = os.getenv("HOMELAB_BACKUP_BASE_DEST")

    def _setup_logging(self) -> logging.Logger:
        logger = logging.getLogger("backrest")
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler(sys.stdout)

        if self.json_logs:
            handler.setFormatter(JsonFormatter())
        else:
            formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
            handler.setFormatter(formatter)

        logger.addHandler(handler)

        if self.dry_run:
            logger.info("DRY-RUN MODE ENABLED - No files will be modified.")

        return logger

    def _get_config(
        self, key: str, container: Optional[Any] = None, default: Any = None
    ) -> Any:
        env_key = key.upper().replace(".", "_")
        if container and key in container.labels:
            return container.labels[key]
        return os.getenv(env_key, default)

    def _get_image(self, container: Optional[Any]) -> str:
        if not container:
            return "N/A (Host Service)"
        try:
            return container.image.tags[0]
        except (IndexError, AttributeError, TypeError):
            return "unknown:latest"

    def run_backup(self, name: str, b_type: str) -> None:
        container = None
        enable_key = (
            "homelab.backup.enable" if b_type == "docker" or b_type == "container" else "HOMELAB_BACKUP_ENABLE"
        )

        if b_type == "docker" or b_type == "container":
            if not self.client:
                raise BackupError("Docker/Podman API is inaccessible.")
            try:
                container = self.client.containers.get(name)
            except docker.errors.NotFound:
                raise BackupError(f"Container not found: {name}")

        enabled = self._get_config(enable_key, container, "false")
        if str(enabled).lower() != "true":
            raise BackupError(
                f"Backup not enabled for {name} ({enable_key} is not true)"
            )

        source_path = self._get_config("homelab.backup.path", container)
        if not source_path:
            raise BackupError(f"Missing backup path for {name}")

        ssh_dest = self._get_config("homelab.backup.ssh.dest", container, os.getenv("HOMELAB_BACKUP_SSH_DEST", "thurs@192.168.10.12:/fast/backups"))

        # Isolate new rsync paths from old tar paths
        safe_b_type = "container" if b_type == "docker" else "file"

        import socket
        hostname = socket.gethostname()

        if not ssh_dest:
            raise BackupError("No SSH destination configured")

        dest_dir = f"{ssh_dest}/{hostname}/{safe_b_type}/{name}"

        config = {
            "target": name,
            "type": b_type,
            "source_path": source_path,
            "destination": dest_dir,
            "image": self._get_image(container),
        }

        include_path = self._get_config("homelab.backup.path.include", container, "")
        if include_path:
            config["include"] = include_path

        ignore_path = self._get_config("homelab.backup.path.ignore", container, "")
        if ignore_path:
            config["ignore"] = ignore_path

        if self.json_logs:
            self.logger.info(
                f"Resolved configuration for {name}", {"resolved_config": config}
            )
        else:
            self.logger.info(f"--- Configuration for {name} ---")
            for key, value in config.items():
                self.logger.info(f"  {key}: {value if value != '' else '(empty)'}")
            self.logger.info("-" * 30)

        self.execute_backup_logic(
            container, source_path, dest_dir, config, manual_name=name
        )

    def execute_backup_logic(
        self,
        container: Optional[Any],
        source: str,
        dest: str,
        config: Dict[str, Any],
        manual_name: str,
    ) -> None:
        container_name = container.name if container else manual_name
        source_path = Path(source)

        # 1. Write metadata JSON
        metadata = {
            "backup_timestamp": datetime.now().isoformat(),
            "configuration": config,
        }

        try:
            if not self.dry_run:
                with open(source_path / "backup_metadata.json", "w") as f:
                    json.dump(metadata, f, indent=4)
        except Exception as e:
            self.logger.warning(f"Failed to write metadata JSON: {e}")

        # 2. Build rsync command
        cmd: List[str] = [
            "rsync",
            "-avz",
            "--delete",
            "--mkpath",
            "--stats",
        ]

        cmd.extend(["-e", "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=accept-new"])

        if config.get("ignore"):
            for ignore in config["ignore"].split(","):
                if ignore.strip():
                    cmd.append(f"--exclude={ignore.strip()}")

        # Source must have trailing slash to sync contents, not the directory itself
        cmd.append(f"{source_path}/")
        cmd.append(dest)

        if self.dry_run:
            self.logger.info(f"Dry-run command: {' '.join(cmd)}")
            return

        start_time = time.time()
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            duration = round(time.time() - start_time, 2)

            if result.returncode != 0:
                stderr_output = result.stderr.strip()
                self.logger.error(
                    f"Rsync failed for {container_name}",
                    {"stderr": stderr_output, "code": result.returncode, "duration_seconds": duration},
                )
                raise BackupError(f"Rsync command failed: {stderr_output}")

            # Parse rsync --stats output for Grafana dashboards
            metrics = {
                "duration_seconds": duration,
                "bytes_sent": 0,
                "bytes_received": 0,
                "total_size": 0,
            }

            sent_match = re.search(r'Total bytes sent: ([\d,]+)', result.stdout)
            if sent_match:
                metrics["bytes_sent"] = int(sent_match.group(1).replace(',', ''))
            
            recv_match = re.search(r'Total bytes received: ([\d,]+)', result.stdout)
            if recv_match:
                metrics["bytes_received"] = int(recv_match.group(1).replace(',', ''))
            
            size_match = re.search(r'Total file size: ([\d,]+)', result.stdout)
            if size_match:
                metrics["total_size"] = int(size_match.group(1).replace(',', ''))

            self.logger.info(
                f"Backup successful: {container_name}",
                {
                    "status": "success",
                    "container": container_name,
                    "destination": dest,
                    "metrics": metrics
                },
            )

        except Exception as e:
            raise BackupError(f"Execution failed: {str(e)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Homelab Backup Coordinator")
    parser.add_argument("--backup", action="store_true")
    parser.add_argument("--type", choices=["docker", "path"])
    parser.add_argument("--name", required=True, help="Target name")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")

    args = parser.parse_args()

    backup_type = args.type
    if not backup_type:
        backup_type = "path" if os.getenv("HOMELAB_BACKUP_ENABLE") else "docker"

    manager = BackupManager(dry_run=args.dry_run, json_logs=args.json)

    try:
        if args.backup:
            manager.run_backup(args.name, backup_type)
    except Exception as e:
        manager.logger.critical(f"Backup sequence failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

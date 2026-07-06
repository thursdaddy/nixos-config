# flake8: noqa: E501
import argparse
import hashlib
import json
import logging
import os
import subprocess
import sys
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

        self.global_base = Path(os.getenv("HOMELAB_BACKUP_BASE_DEST", "/mnt/backups"))

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

    def _get_image_version(self, container: Optional[Any]) -> str:
        if not container:
            return "null"
        try:
            full_tag = container.image.tags[0]
            return full_tag.split(":")[-1] if ":" in full_tag else "latest"
        except (IndexError, AttributeError, TypeError):
            return "latest"

    def _calculate_checksum(self, file_path: Path) -> str:
        # Kept for backward compatibility if needed, but unused by rsync
        pass

    def _format_size(self, size_bytes: int) -> str:
        if size_bytes == 0:
            return "0 B"
        size_float = float(size_bytes)
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if size_float < 1024.0:
                return f"{size_float:.2f} {unit}"
            size_float /= 1024.0
        return f"{size_float:.2f} PB"

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

        # Resolve destination dynamically: Label -> Env Var -> Global Default
        base_dest = self._get_config(
            "homelab.backup.base.dest", container, self.global_base
        )
        ssh_dest = self._get_config("homelab.backup.ssh.dest", container, os.getenv("HOMELAB_BACKUP_SSH_DEST", ""))

        config = {
            "target": name,
            "type": b_type,
            "source_path": source_path,
            "base_destination": str(base_dest),
            "retention": int(
                self._get_config("homelab.backup.retention.period", container, 5)
            ),
            "include": self._get_config("homelab.backup.path.include", container, ""),
            "ignore": self._get_config("homelab.backup.path.ignore", container, ""),
        }

        if self.json_logs:
            self.logger.info(
                f"Resolved configuration for {name}", {"resolved_config": config}
            )
        else:
            self.logger.info(f"--- Configuration for {name} ---")
            for key, value in config.items():
                self.logger.info(f"  {key}: {value if value != '' else '(empty)'}")
            self.logger.info("-" * 30)

        # Isolate new rsync paths from old tar paths
        safe_b_type = "container" if b_type == "docker" else "file"

        import socket
        hostname = socket.gethostname()

        if ssh_dest:
            dest_dir = f"{ssh_dest}/{hostname}/{safe_b_type}/{name}/current"
            is_ssh = True
        else:
            dest_dir = str(Path(base_dest) / safe_b_type / name / "current")
            is_ssh = False

        self.execute_backup_logic(
            container, source_path, dest_dir, config, is_ssh, manual_name=name
        )

    def execute_backup_logic(
        self,
        container: Optional[Any],
        source: str,
        dest: str,
        config: Dict[str, Any],
        is_ssh: bool,
        manual_name: str,
    ) -> None:
        container_name = container.name if container else manual_name
        image_version = self._get_image_version(container)
        source_path = Path(source)

        # 1. Write metadata JSON
        metadata = {
            "backup_timestamp": datetime.now().isoformat(),
            "configuration": config,
        }
        if container:
            metadata["image"] = image_version
        else:
            metadata["image"] = "N/A (Host Service)"

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
        ]

        if is_ssh:
            cmd.extend(["-e", "ssh -o StrictHostKeyChecking=accept-new"])
        else:
            # Local/NFS destination, ensure parent exists
            Path(dest).parent.mkdir(parents=True, exist_ok=True)

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

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode != 0:
                stderr_output = result.stderr.strip()
                self.logger.error(
                    f"Rsync failed for {container_name}",
                    {"stderr": stderr_output, "code": result.returncode},
                )
                raise BackupError(f"Rsync command failed: {stderr_output}")

            self.logger.info(
                f"Backup successful: {container_name}",
                {
                    "status": "success",
                    "container": container_name,
                    "destination": dest,
                },
            )

        except Exception as e:
            raise BackupError(f"Execution failed: {str(e)}")

    def rotate_backups(self, b_type: str, name: str) -> None:
        self.logger.info(
            f"Rotation skipped for {name} - ZFS auto-snapshot manages retention natively.",
            {"status": "skipped", "container": name}
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Homelab Backup Coordinator")
    parser.add_argument("--backup", action="store_true")
    parser.add_argument("--rotate", action="store_true")
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
        if args.rotate:
            manager.rotate_backups(backup_type, args.name)
    except Exception as e:
        manager.logger.critical(f"Backup sequence failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

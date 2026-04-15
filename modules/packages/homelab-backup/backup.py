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

        try:
            self.client = docker.from_env()
            self.client.ping()
        except Exception:
            self.logger.debug("Docker socket not reachable; Docker features disabled.")
            self.client = None

        # This serves as the global system default
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
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

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
            "homelab.backup.enable" if b_type == "docker" else "HOMELAB_BACKUP_ENABLE"
        )

        if b_type == "docker":
            if not self.client:
                raise BackupError("Docker is inaccessible.")
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
        base_dest = self._get_config("homelab.backup.base.dest", container, self.global_base)

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

        dest_dir = Path(base_dest) / b_type / name
        self.execute_backup_logic(
            container, source_path, dest_dir, config, manual_name=name
        )

    def execute_backup_logic(
        self,
        container: Optional[Any],
        source: str,
        dest: Path,
        config: Dict[str, Any],
        manual_name: str,
    ) -> None:
        container_name = container.name if container else manual_name
        image_version = self._get_image_version(container)
        now_str = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
        tar_filename = f"{now_str}-{container_name}-{image_version}.tar.gz"
        full_dest_path = dest / tar_filename

        source_path = Path(source)

        cmd: List[str] = [
            "tar",
            "--sort=name",
            "--mtime=UTC 1970-01-01 00:00:00",
            "-czf",
            str(full_dest_path),
            "-C",
            str(source_path.parent),
            source_path.name,
        ]

        if config.get("ignore"):
            for ignore in config["ignore"].split(","):
                if ignore.strip():
                    cmd.insert(1, f"--exclude={ignore.strip()}")

        if config.get("include"):
            for include in config["include"].split(","):
                if include.strip():
                    cmd.append(include.strip())

        if self.dry_run:
            self.logger.info(f"Dry-run command: {' '.join(cmd)}")
            return

        try:
            dest.mkdir(parents=True, exist_ok=True)
            existing_backups = sorted(
                dest.glob("*.tar.gz"), key=os.path.getmtime, reverse=True
            )
            latest_existing = existing_backups[0] if existing_backups else None

            env = os.environ.copy()
            env["GZIP"] = "-n"

            result = subprocess.run(cmd, capture_output=True, text=True, env=env)

            if result.returncode != 0:
                stderr_output = result.stderr.strip()
                self.logger.error(
                    f"Tar failed for {container_name}",
                    {"stderr": stderr_output, "code": result.returncode},
                )
                raise BackupError(f"Tar command failed: {stderr_output}")

            new_checksum = self._calculate_checksum(full_dest_path)

            if latest_existing:
                old_checksum = self._calculate_checksum(latest_existing)
                if new_checksum == old_checksum:
                    self.logger.info(
                        f"No changes detected for {container_name}. Removing duplicate.",
                        {"status": "skipped_duplicate", "container": container_name},
                    )
                    full_dest_path.unlink()
                    return

            self.logger.info(
                f"Backup successful: {container_name}",
                {
                    "status": "success",
                    "container": container_name,
                    "size_bytes": full_dest_path.stat().st_size,
                },
            )

        except Exception as e:
            if full_dest_path.exists():
                full_dest_path.unlink()
            raise BackupError(f"Execution failed: {str(e)}")

    def rotate_backups(self, b_type: str, name: str) -> None:
        container = None
        if b_type == "docker" and self.client:
            try:
                container = self.client.containers.get(name)
            except:
                pass

        retention = int(
            self._get_config("homelab.backup.retention.period", container, 5)
        )

        # Resolve destination for rotation as well
        base_dest = self._get_config("homelab.backup.base.dest", container, self.global_base)
        dest_dir = Path(base_dest) / b_type / name

        if not dest_dir.exists():
            return

        archives = sorted(dest_dir.glob("*.tar.gz"), key=os.path.getmtime, reverse=True)

        if len(archives) > retention:
            to_delete = archives[retention:]
            for archive in to_delete:
                if not self.dry_run:
                    archive.unlink()
                self.logger.info(
                    f"Deleted old backup: {archive.name}", {"action": "deleted"}
                )

            archives = sorted(
                dest_dir.glob("*.tar.gz"), key=os.path.getmtime, reverse=True
            )

        total_bytes = sum(a.stat().st_size for a in archives)
        inventory = [{"name": a.name, "size_bytes": a.stat().st_size} for a in archives]

        if self.json_logs:
            self.logger.info(
                f"Inventory for {name}",
                {"total_size_bytes": total_bytes, "inventory": inventory},
            )
        else:
            self.logger.info(f"--- Inventory for {name} ---")
            for a in archives:
                self.logger.info(f"  {a.name} ({self._format_size(a.stat().st_size)})")
            self.logger.info(f"--- Total Size: {self._format_size(total_bytes)} ---")


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

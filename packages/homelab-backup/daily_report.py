#!/usr/bin/env python3
import os
import re
import sys
import json
import time
import requests
from datetime import datetime, timedelta

def format_size(size_bytes):
    if size_bytes is None:
        return "N/A"
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"

def format_duration(seconds):
    if seconds is None:
        return "N/A"
    if seconds < 60.0:
        return f"{seconds:.2f}s"
    minutes = int(seconds // 60)
    secs = seconds % 60
    return f"{minutes}m {secs:.0f}s"

def main():
    gotify_url = os.getenv("GOTIFY_URL")
    gotify_token = os.getenv("GOTIFY_APP_TOKEN")
    loki_url = os.getenv("LOKI_URL", "http://192.168.10.68:3100")

    if not gotify_url or not gotify_token:
        print("Error: GOTIFY_URL and GOTIFY_APP_TOKEN must be set.", file=sys.stderr)
        sys.exit(1)

    # 1. Calculate midnight (12:00 AM) of the current day
    now = datetime.now()
    midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
    start_ns = int(midnight.timestamp() * 1e9)
    
    query = '{unit=~"backup-.*.service"}'
    params = {
        'query': query,
        'start': start_ns,
        'limit': 5000
    }
    
    try:
        response = requests.get(f"{loki_url}/loki/api/v1/query_range", params=params, timeout=30)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        print(f"Failed to query Loki: {e}", file=sys.stderr)
        # Send error alert to Gotify
        requests.post(
            f"{gotify_url}/message",
            headers={"X-Gotify-Key": gotify_token},
            json={
                "title": "Backup Report Error",
                "message": f"Failed to fetch daily backup logs from Loki: {e}",
                "priority": 5
            }
        )
        sys.exit(1)

    streams = data.get("data", {}).get("result", [])
    
    # We must collect log lines from all streams and merge them chronologically
    # to prevent earlier failed streams from overwriting later successful streams.
    raw_backups = {}

    for stream_data in streams:
        labels = stream_data.get("stream", {})
        host = labels.get("host", "unknown")
        unit = labels.get("unit", "unknown")
        service_name = unit.replace(".service", "")
        
        key = (host, service_name)
        if key not in raw_backups:
            raw_backups[key] = []
            
        for ts_str, line in stream_data.get("values", []):
            raw_backups[key].append((int(ts_str), line))

    backups = {}

    # 2. Process merged log lines chronologically
    for key, log_lines in raw_backups.items():
        host, service_name = key
        
        # Sort chronologically by timestamp
        sorted_lines = sorted(log_lines, key=lambda x: x[0])
        
        backup = {
            "host": host,
            "service": service_name,
            "status": "Unknown",
            "duration": None,
            "bytes_sent": None,
            "total_size": None,
            "last_run": 0,
            "errors": []
        }
        
        for ts_ns, line in sorted_lines:
            ts = ts_ns / 1e9
            if ts > backup["last_run"]:
                backup["last_run"] = ts
                
            # Check for failure indications in the log line
            if any(err in line.lower() for err in ["failed", "critical", "error", "exit-code", "rsync error"]):
                # Filter out harmless paths containing the word "errors"
                if "errors-root-cause.png" not in line and "errors-metric-flow.png" not in line:
                    backup["errors"].append(line)
                    backup["status"] = "Failed"

            # Parse homelab-backup JSON metrics
            if "Resolved configuration" in line or "resolved_config" in line:
                # Started a new run, reset state for this run
                backup["errors"] = []
                backup["status"] = "Running"
                
            if "Backup successful" in line or "status\": \"success" in line:
                backup["status"] = "Success"
                backup["errors"] = []  # Clear any transient errors from previous runs
                # Extract metrics from JSON
                try:
                    # Find JSON substring
                    json_start = line.find('{')
                    if json_start != -1:
                        log_data = json.loads(line[json_start:])
                        metrics = log_data.get("metrics", {})
                        if metrics:
                            backup["duration"] = metrics.get("duration_seconds")
                            backup["bytes_sent"] = metrics.get("bytes_sent")
                            backup["total_size"] = metrics.get("total_size")
                except Exception:
                    pass

            # Fallback text parses for custom script outputs (rsync stats)
            sent_match = re.search(r'sent ([\d,]+) bytes  received ([\d,]+) bytes', line)
            if sent_match:
                backup["bytes_sent"] = int(sent_match.group(1).replace(',', ''))
                
            size_match = re.search(r'total size is ([\d,]+)', line)
            if size_match:
                backup["total_size"] = int(size_match.group(1).replace(',', ''))
                
            # Systemd success exit
            if "Deactivated successfully" in line or "Finished Backups for" in line or "Finished Reverse tunnel rsync" in line:
                if backup["status"] != "Failed":
                    backup["status"] = "Success"
                    backup["errors"] = []
                    
            # Capture systemd consumed duration if available
            consumed_match = re.search(r'Consumed ([\d\.\w]+) CPU time', line)
            if consumed_match and backup["duration"] is None:
                # Systemd logs format like "1.083s CPU time"
                dur_str = consumed_match.group(1)
                if dur_str.endswith("s"):
                    try:
                        backup["duration"] = float(dur_str[:-1])
                    except ValueError:
                        pass

        backups[key] = backup

    # 3. Format Markdown Report
    successful_count = 0
    failed_count = 0
    
    rows = []
    # Sort by host, then service name
    for key in sorted(backups.keys(), key=lambda x: (x[0], x[1])):
        b = backups[key]
        
        # If no status was determined, check last_run to see if it even ran today
        if b["status"] == "Unknown" and b["last_run"] > 0:
            b["status"] = "Success"  # Assume success if no errors were logged
            
        # Determine status symbol
        if b["status"] == "Success":
            status_icon = "✅"
            successful_count += 1
        elif b["status"] == "Failed" or b["errors"]:
            status_icon = "❌"
            failed_count += 1
        else:
            status_icon = "❓"
            
        duration_formatted = format_duration(b["duration"])
        sent_formatted = format_size(b["bytes_sent"])
        size_formatted = format_size(b["total_size"])
        
        rows.append(f"| {b['host']} | `{b['service']}` | {status_icon} | {duration_formatted} | {sent_formatted} | {size_formatted} |")

    # Overall Summary
    total_count = successful_count + failed_count
    summary_title = "📅 Daily Backup Report"
    if failed_count > 0:
        summary_title = "⚠️ Backup Report: Failures Detected"
        priority = 8
    else:
        priority = 5

    report_markdown = f"""### Backup Summary ({midnight.strftime('%Y-%m-%d')})
* **Successful**: {successful_count}
* **Failed**: {failed_count}
* **Total**: {total_count}

| Host | Service | Status | Duration | Sent | Total Size |
| :--- | :--- | :---: | :--- | :--- | :--- |
""" + "\n".join(rows)

    # List any errors for visibility
    errors_section = []
    for key in sorted(backups.keys(), key=lambda x: (x[0], x[1])):
        b = backups[key]
        if b["errors"]:
            errors_section.append(f"#### ❌ {b['host']} - `{b['service']}` Errors:")
            for err in b["errors"][-5:]:  # show last 5 error lines
                errors_section.append(f"> {err.strip()}")
                
    if errors_section:
        report_markdown += "\n\n### 🚨 Error Logs\n" + "\n".join(errors_section)

    # 4. Push message to Gotify
    payload = {
        "title": summary_title,
        "message": report_markdown,
        "priority": priority,
        "extras": {
            "client::display": {
                "contentType": "text/markdown"
            }
        }
    }
    
    try:
        res = requests.post(f"{gotify_url}/message", headers={"X-Gotify-Key": gotify_token}, json=payload, timeout=10)
        res.raise_for_status()
        print("Backup report successfully pushed to Gotify.")
    except Exception as e:
        print(f"Failed to push message to Gotify: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

### Python script to Automated Prometheus Node Exporter Installer + Prometheus Config Updater.

## ✅ How to Use
### prerequisites:
* Python 3
* PyYAML installed
* Root permissions
* promtool installed (for YAML validation)

#### Install Python 3 Locally
```sh
sudo apt update
sudo apt install -y python3 python3-pip
```

Verify Python3 Installation:
```sh
python3 --version
```

#### Ensure promtool exists:
```sh
which promtool
```

#### Install dependencies:
Create a Virtual Environment
```sh
sudo apt install -y python3-venv
```
Then, inside your scripts directory:
```sh
cd /opt/devops/scripts
python3 -m venv venv
```
Activate it:
```sh
source venv/bin/activate
```
Install the required modules inside the venv
```sh
pip install pyyaml requests
```

### Save the script to a file:

#### For node_exporter: 
```sh
sudo nano install_node_exporter.py
```

copy and paste the below script:
```sh
#!/usr/bin/env python3
"""
install_node_exporter_basic.py

Simple installer for Prometheus Node Exporter (basic mode).

- Downloads latest linux-amd64 release from GitHub
- Installs binary to /usr/local/bin/node_exporter
- Creates a system user 'node_exporter' if it does not exist
- Writes systemd service at /etc/systemd/system/node_exporter.service
- Enables & starts the service
- Verifies service status
- Cleans temporary download/extracted files when successful

Run as root (sudo).
"""
import os
import subprocess
import tarfile
import requests
import shutil
import sys

NODE_EXPORTER_USER = "node_exporter"
BINARY_PATH = "/usr/local/bin/node_exporter"
SERVICE_PATH = "/etc/systemd/system/node_exporter.service"
TARBALL = "node_exporter.tar.gz"


def run(cmd, check=True):
    print(f"→ {cmd}")
    result = subprocess.run(cmd, shell=True)
    if check and result.returncode != 0:
        raise SystemExit(f"Command failed: {cmd}")


def download_latest():
    print("\n=== Downloading latest Node Exporter release ===")
    api_url = "https://api.github.com/repos/prometheus/node_exporter/releases/latest"
    resp = requests.get(api_url, timeout=30)
    resp.raise_for_status()
    assets = resp.json().get("assets", [])
    url = None
    for a in assets:
        u = a.get("browser_download_url", "")
        if "linux-amd64.tar.gz" in u:
            url = u
            break
    if not url:
        raise SystemExit("Could not find linux-amd64 tarball in the latest release assets.")
    print(f"Found: {url}")
    run(f"wget -q {url} -O {TARBALL}")
    print("Download complete.")


def extract_and_get_folder():
    print("\n=== Extracting tarball ===")
    with tarfile.open(TARBALL, "r:gz") as tar:
        tar.extractall()
    # find extracted folder
    for name in os.listdir("."):
        if name.startswith("node_exporter") and os.path.isdir(name):
            return name
    raise SystemExit("Extraction succeeded but could not locate extracted folder.")


def install_binary(folder):
    print("\n=== Installing node_exporter binary ===")
    # create user if not exists (no error on existence)
    run(f"id -u {NODE_EXPORTER_USER} || useradd -rs /bin/false {NODE_EXPORTER_USER}", check=False)

    src = os.path.join(folder, "node_exporter")
    if not os.path.exists(src):
        raise SystemExit(f"Binary not found in extracted folder: {src}")

    # backup existing binary if present and different
    if os.path.exists(BINARY_PATH):
        try:
            out = subprocess.check_output(f"{BINARY_PATH} --version", shell=True, universal_newlines=True)
            print(f"Existing node_exporter detected: {out.strip()}")
        except Exception:
            print("Existing node_exporter binary detected (no version output). Backing up.")
        backup_path = BINARY_PATH + ".bak"
        print(f"Backing up existing binary to {backup_path}")
        shutil.copy2(BINARY_PATH, backup_path)

    run(f"mv {src} {BINARY_PATH}")
    run(f"chown {NODE_EXPORTER_USER}:{NODE_EXPORTER_USER} {BINARY_PATH}")
    run(f"chmod 0755 {BINARY_PATH}")


def install_service():
    print("\n=== Installing systemd service ===")
    service_content = f"""[Unit]
Description=Node Exporter
After=network.target

[Service]
User={NODE_EXPORTER_USER}
Group={NODE_EXPORTER_USER}
Type=simple
ExecStart={BINARY_PATH}
Restart=on-failure

[Install]
WantedBy=default.target
"""
    with open(SERVICE_PATH, "w") as f:
        f.write(service_content)

    run("systemctl daemon-reload")
    run("systemctl enable node_exporter")
    run("systemctl restart node_exporter")


def check_status():
    print("\n=== Checking node_exporter service status ===")
    rc = subprocess.run("systemctl is-active node_exporter", shell=True)
    if rc.returncode == 0:
        print("✅ node_exporter is active and running.")
    else:
        print("❌ node_exporter is not running. Inspect logs with: journalctl -u node_exporter -xe")
        raise SystemExit("node_exporter failed to start.")


def cleanup(folder):
    print("\n=== Cleaning workspace ===")
    try:
        if os.path.exists(TARBALL):
            os.remove(TARBALL)
        if folder and os.path.exists(folder):
            shutil.rmtree(folder)
        print("Workspace cleaned: removed tarball and extracted folder.")
    except Exception as e:
        print(f"Cleanup skipped due to error: {e}")


def main():
    if os.geteuid() != 0:
        raise SystemExit("This script must be run as root (sudo).")

    try:
        download_latest()
        folder = extract_and_get_folder()
        install_binary(folder)
        install_service()
        check_status()
    except Exception as e:
        print(f"\nERROR: {e}")
        print("Aborting. Temporary files have been left for inspection.")
        sys.exit(1)

    # only cleanup after everything succeeded
    cleanup(folder)
    print("\nAll done. Node Exporter installed and running.")


if __name__ == "__main__":
    main()
```
## For prometheus Config Updater: 
```sh
sudo nano prometheus_add_target.py
```

copy and paste the below script:
```sh
#!/usr/bin/env python3
import os
import yaml
import subprocess

PROM_CONFIG_PATH = "/etc/prometheus/prometheus.yml"


def run(cmd, check=True):
    print(f"→ {cmd}")
    result = subprocess.run(cmd, shell=True)
    if check and result.returncode != 0:
        raise SystemExit(f"Command failed: {cmd}")


def ask_optional(prompt, allow_empty=True):
    value = input(prompt).strip()
    return value if value != "" else None


def parse_dict_input(raw):
    """
    Parse dict-style input like:
    env=prod,team=backend
    into: {"env": "prod", "team": "backend"}
    """
    if not raw:
        return None

    items = raw.split(",")
    result = {}
    for item in items:
        if "=" in item:
            k, v = item.split("=", 1)
            result[k.strip()] = v.strip()
    return result if result else None


def parse_relabel_input(raw):
    """
    Parse simple relabel rules like:
    source_labels=__address__, regex=(.*), target_label=instance

    You may extend this format later.
    """
    if not raw:
        return None

    relabels = []
    rules = raw.split(";")
    for rule in rules:
        rule = rule.strip()
        if not rule:
            continue

        kv_pairs = rule.split(",")
        rule_dict = {}

        for kv in kv_pairs:
            if "=" in kv:
                k, v = kv.split("=", 1)
                rule_dict[k.strip()] = v.strip()

        if rule_dict:
            relabels.append(rule_dict)

    return relabels if relabels else None


def update_prometheus_config(job_name, targets, scrape_interval=None,
                             labels=None, metrics_path=None, scheme=None,
                             bearer_token_file=None, relabel_configs=None):

    print("\n=== Updating Prometheus YAML ===")

    with open(PROM_CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

    scrape_configs = config.get("scrape_configs", [])

    # Ensure job doesn't already exist
    for job in scrape_configs:
        if job.get("job_name") == job_name:
            raise SystemExit(f"❌ Job '{job_name}' already exists in prometheus.yml")

    # Construct job block dynamically
    new_job = {
        "job_name": job_name,
        "static_configs": [{"targets": targets}]
    }

    # Add optional fields only if provided
    if scrape_interval:
        new_job["scrape_interval"] = scrape_interval

    if metrics_path:
        new_job["metrics_path"] = metrics_path

    if scheme:
        new_job["scheme"] = scheme

    if bearer_token_file:
        new_job["bearer_token_file"] = bearer_token_file

    if labels:
        new_job["static_configs"][0]["labels"] = labels

    if relabel_configs:
        new_job["relabel_configs"] = relabel_configs

    # Append to scrape configs
    scrape_configs.append(new_job)
    config["scrape_configs"] = scrape_configs

    # Write final YAML
    with open(PROM_CONFIG_PATH, "w") as f:
        yaml.safe_dump(config, f, sort_keys=False)

    print("Prometheus config updated successfully.")


def validate_and_restart():
    print("\n=== Validating Prometheus config ===")
    result = subprocess.run(f"promtool check config {PROM_CONFIG_PATH}", shell=True)

    if result.returncode != 0:
        raise SystemExit("❌ promtool validation failed. Fix the config!")

    print("✔ promtool validation succeeded")

    print("\nRestarting Prometheus...")
    run("systemctl restart prometheus")

    print("\nChecking Prometheus status...")
    status = subprocess.run("systemctl is-active prometheus", shell=True)

    if status.returncode == 0:
        print("✅ Prometheus is running correctly.")
    else:
        print("❌ Prometheus failed to start! Check logs using:")
        print("journalctl -u prometheus -xe")
        raise SystemExit()


def main():
    print("\n--- Prometheus Job Config Updater (Advanced Mode) ---")

    job_name = input("Enter job name: ").strip()
    target = input("Enter target (IP:port): ").strip()

    # Optional fields
    scrape_interval = ask_optional("scrape_interval (optional): ")
    metrics_path = ask_optional("metrics_path (optional): ")
    scheme = ask_optional("scheme (http/https) (optional): ")
    bearer_token_file = ask_optional("bearer_token_file (optional): ")

    raw_labels = ask_optional("labels (format: k=v,k=v) (optional): ")
    labels = parse_dict_input(raw_labels)

    raw_relabel = ask_optional("relabel_configs (format: k=v,k=v; k=v,k=v) (optional): ")
    relabel_configs = parse_relabel_input(raw_relabel)

    update_prometheus_config(
        job_name=job_name,
        targets=[target],
        scrape_interval=scrape_interval,
        labels=labels,
        metrics_path=metrics_path,
        scheme=scheme,
        bearer_token_file=bearer_token_file,
        relabel_configs=relabel_configs
    )

    validate_and_restart()


if __name__ == "__main__":
    if os.geteuid() != 0:
        raise SystemExit("You must run this script as root (sudo).")
    main()
```
### Run the script:
If it is VENV:
```sh
sudo /opt/devops/scripts/venv/bin/python /opt/devops/scripts/install_node_exporter.py
```
```sh
sudo venv/bin/python prometheus_add_target.py
```
ELSE
```sh
sudo python3 /opt/devops/scripts/install_node_exporter.py
```

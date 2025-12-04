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
```sh
sudo nano install_node_exporter.py
```

copy and paste the below script
```sh
#!/usr/bin/env python3
import os
import yaml
import subprocess
import requests
import tarfile
import getpass
import shutil

PROM_CONFIG_PATH = "/etc/prometheus/prometheus.yml"
NODE_EXPORTER_USER = "node_exporter"


def run(cmd, check=True):
    print(f"→ {cmd}")
    result = subprocess.run(cmd, shell=True)
    if check and result.returncode != 0:
        raise SystemExit(f"Command failed: {cmd}")


def download_latest_node_exporter():
    print("\n=== Downloading latest Node Exporter release ===")

    api_url = "https://api.github.com/repos/prometheus/node_exporter/releases/latest"
    response = requests.get(api_url)
    response.raise_for_status()

    assets = response.json()["assets"]
    url = None
    for a in assets:
        if "linux-amd64.tar.gz" in a["browser_download_url"]:
            url = a["browser_download_url"]
            break

    if not url:
        raise SystemExit("Could not find linux-amd64 build.")

    print(f"Downloading: {url}")
    run(f"wget -q {url} -O node_exporter.tar.gz")

    print("Extracting...")
    with tarfile.open("node_exporter.tar.gz", "r:gz") as tar:
        tar.extractall()

    folder = next(
        f for f in os.listdir(".") if f.startswith("node_exporter") and os.path.isdir(f)
    )
    return folder


def install_node_exporter(folder):
    print("\n=== Installing Node Exporter ===")

    run(f"id -u {NODE_EXPORTER_USER} || useradd -rs /bin/false {NODE_EXPORTER_USER}", check=False)

    run(f"mv {folder}/node_exporter /usr/local/bin/")
    run(f"chown {NODE_EXPORTER_USER}:{NODE_EXPORTER_USER} /usr/local/bin/node_exporter")

    systemd_service = f"""
[Unit]
Description=Node Exporter
After=network.target

[Service]
User={NODE_EXPORTER_USER}
Group={NODE_EXPORTER_USER}
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=default.target
"""

    with open("/etc/systemd/system/node_exporter.service", "w") as f:
        f.write(systemd_service)

    run("systemctl daemon-reload")
    run("systemctl enable node_exporter")
    run("systemctl restart node_exporter")


def update_prometheus_config(job_name, target):
    print("\n=== Updating Prometheus YAML ===")

    with open(PROM_CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

    scrape_configs = config.get("scrape_configs", [])

    for job in scrape_configs:
        if job.get("job_name") == job_name:
            raise SystemExit(f"Job '{job_name}' already exists in prometheus.yml")

    new_job = {
        "job_name": job_name,
        "static_configs": [{"targets": [target]}]
    }

    scrape_configs.append(new_job)
    config["scrape_configs"] = scrape_configs

    with open(PROM_CONFIG_PATH, "w") as f:
        yaml.safe_dump(config, f, sort_keys=False)

    print("Prometheus config updated.")


def validate_and_restart_prometheus():
    print("\n=== Validating Prometheus config ===")
    result = subprocess.run(f"promtool check config {PROM_CONFIG_PATH}", shell=True)

    if result.returncode != 0:
        raise SystemExit("❌ promtool validation failed. Fix prometheus.yml manually!")

    print("Config OK. Restarting Prometheus...")
    run("systemctl restart prometheus")

    print("\n=== Checking Prometheus status ===")
    status = subprocess.run("systemctl is-active prometheus", shell=True)

    if status.returncode == 0:
        print("✅ Prometheus is running fine.")
    else:
        print("❌ Prometheus failed to start! Check logs:")
        print("journalctl -u prometheus -xe")
        raise SystemExit()


def main():
    print("\n--- Node Exporter Installer + Prometheus Config Updater ---")

    job_name = input("Enter job name: ")
    target = input("Enter target (e.g. localhost:9100): ")

    folder = download_latest_node_exporter()
    install_node_exporter(folder)
    update_prometheus_config(job_name, target)
    validate_and_restart_prometheus()

    print("\n=== Cleaning up workspace ===")
    try:
        if os.path.exists("node_exporter.tar.gz"):
            os.remove("node_exporter.tar.gz")

        if os.path.exists(folder):
            shutil.rmtree(folder)

        print("Workspace cleaned successfully.")
    except Exception as e:
        print(f"Cleanup skipped due to error: {e}")

    print("\n🎉 All tasks completed successfully!")


if __name__ == "__main__":
    if os.geteuid() != 0:
        raise SystemExit("You must run this script as root (sudo).")
    main()
```

### Run the script:
If is VENV
```sh
sudo venv/bin/python install_node_exporter.py
```
ELSE
```sh
sudo python3 /opt/devops/scripts/install_node_exporter.py
```

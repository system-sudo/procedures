# 🧭 Overview

* Prepare the agent machine
* Create the node in Jenkins UI
* Connect the agent to the controller
* Verify and test the connection

## 🖥️ Step 1: Prepare the Agent Machine (192.168.6.2)
### ✅ Requirements

Make sure the agent machine has:

* Java installed (Jenkins agents need it)
* A user with permission to run builds (e.g., jenkins or ubuntu)

### 🧩 Install Java (if not installed)
```sh
sudo apt update
sudo apt install openjdk-17-jre -y
java -version
```

## ⚙️ Step 2: Create Agent Node in Jenkins UI

### Open Jenkins web UI:
eg: 👉 http://192.168.8.39:8080/manage

Go to Manage Jenkins → Nodes → New Node

Fill in:
### Node name:
node-agent1 (or any name you prefer)
Select Permanent Agent

### Number executors:
1 (or more, depending on CPU)

### Remote root directory:
/home/jenkins (or any path)

### Labels:
staging. (or any name you prefer - This will be used in the pipeline)

### Usage:
"Use this node as much as possible" or "Only build jobs with label expressions matching this node"

### Launch method: choose one:

✅ Launch agent by connecting it to the controller (recommended, more secure)
or Launch agent via SSH (simpler setup if you can SSH from controller to agent)

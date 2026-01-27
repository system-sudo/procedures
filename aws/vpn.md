## Site-to-Site VPN
```sh
GCP VPC (10.160.0.0/16)
    |
    |  IPSec VPN
    |
AWS VPC (172.31.0.0/16)
    |
  RDS (private)
```

### Check CIDRs
GCP
```sh
gcloud compute networks subnets list
```
AWS
```sh
VPC Dashboard → Your VPC → CIDR
```
If they overlap → stop and redesign (non-negotiable).
## Step-by-step: AWS side
### 1️⃣ Create Virtual Private Gateway (VGW)
AWS Console → VPC → Virtual Private Gateways
* Create VGW
* Attach it to vpc-12a45f79 (VPC associated Resource)
This is AWS’s VPN anchor.
### 2️⃣ Create Customer Gateway (CGW)
You need GCP’s VPN public IP (static).
#### In GCP:
* You will get this in Step-6
* Reserve a static external IP
* This will be your VPN gateway IP
#### In AWS:
* Create Customer Gateway
* IP = GCP VPN public IP
* Routing = Static (simpler)
### 3️⃣ Create Site-to-Site VPN connection
* VGW → CGW
* Routing: Static
* Remote network:
```sh
10.160.0.0/16   (your GCP subnet) 
```
To get the default GCP subnet of your region:
```sh
gcloud compute networks subnets list
```
#### AWS will give you:
* 2 IPSec tunnels
* Pre-shared keys
* IKE / ESP parameters
  **Download the config — do not ignore it.**
### 4️⃣ Update AWS route table
For the subnet where RDS lives:  
Add route:
```sh
Destination: 10.160.0.0/16
Target: VGW
```
Without this → packets die silently.
### 5️⃣ Security Group
Update credcv-rds-sg:
```sh
Inbound:
MySQL 3306
Source: 10.160.0.0/16
```
## Step-by-step: GCP side
### 6️⃣ Create Cloud VPN gateway
**GCP Console → VPN → Create VPN**
Choose:
* Classic VPN (simpler with AWS) OR HA VPN
* Static routing
### 7️⃣ Create VPN tunnel
Use AWS-provided: (Downloaded in Step 3) 
* Peer IP
* Pre-shared key
* IKE version
* Encryption params
Remote traffic selector:
```sh
172.31.0.0/16   (AWS VPC CIDR)
```
Local traffic selector:
```sh
10.160.0.0/16 (GCP mumbai region CIDR)
```
### 8️⃣ Add GCP route
**GCP Console → VPC → route**  
Create route:
```sh
Destination: 172.31.0.0/16
Next hop: VPN tunnel
Priority: lower than default (e.g. 1000)
```
This is the mirror of the AWS route.
### 9️⃣ GCP firewall rule
Allow outbound from GCP VM firewall:
```sh
Direction: Egress
Target: backend-api-server (server name)
Destination: 172.31.0.0/16
Protocol: tcp:3306
```
### Validation
From GCP VM
```sh
nc -vz <RDS-private-IP/endpoint> 3306
```
You must see:
```sh
succeeded
```
If this fails → VPN or routing is broken
#### Step 1 — Are you routing to the VPN at all? (GCP side)
On the GCP VM, run:
```sh
ip route get 172.31.28.231
```
✅ Correct output should look like:
```sh
172.31.28.231 via <vpn-interface-ip> dev <vpn-interface>
```

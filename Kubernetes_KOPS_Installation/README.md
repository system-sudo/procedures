# USING THE KOPS METHOD CREATE A KUBERNETES CLUSTER 

![Sample Image](https://drive.google.com/uc?export=view&id=174hu4SZa1pCvQFPm3O0l3TRctWta-oWX)


## REQUIREMENTS
1. Linux machine (ubuntu)
2. AWS account
3. kops binary (Kubernetes cluster initiate)
4. kubectl binary (Kubernetes deployments)

## Update the Ubuntu Server 
  ```bash
  sudo apt-get update -y
```
## Need to install unzip 
```bash
  sudo apt install unzip -y
```
## To install the AWS CLI, run the following commands.
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```
## Unzip the awscli 
```bash
unzip awscliv2.zip
```
## Install the awscli
```bash
sudo ./aws/install
```

## KOPS BINARY SETUP
### 1. Download the latest Kops binary:
   ```bash
   curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
   ```
### 2. Make the binary executable:
   ```bash
   chmod +x ./kops
```
### 3. Move the binary to a directory in your PATH:
   ```bash
   sudo mv ./kops /usr/local/bin/
```
## KUBECTL BINARY SETUP
### 1. Download the latest Kubectl binary:
   ```bash
   curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
```
### 2. Make the binary executable:
   ```bash
   chmod +x ./kubectl
```
### 3. Move the binary to a directory in your PATH:
   ```bash
   sudo mv ./kubectl /usr/local/bin/kubectl
```

## SETUP IAM USER (kops access aws resources)
### This is the working method for AWS CLI commands. Kindly configure aws-cli packages for your Linux machines.

To build clusters within AWS, we'll create a dedicated IAM user for Kops. This user requires API credentials to use Kops. Create the user and credentials using the AWS console.
The kops user will require the following IAM permissions to function properly: or You can create now with admin access for testing.
  
   1. AmazonEC2FullAccess
   2. AmazonRoute53FullAccess
   3. AmazonS3FullAccess
   4. IAMFullAccess
   5. AmazonVPCFullAccess

Use AWS Console to Create a IAM User with new access and secret key and enter it here
## Configure the AWS client to use your new IAM user

```bash
aws configure
```
Create a S3 Bucket for etcd Storage in AWS Console
## Verify AWS client
you should see a list of all your S3 Buckets
```bash    
aws s3 ls
```
you should see a list of all your IAM users here
```bash    
aws iam list-users
```

## Prepare local environment

### We're ready to start creating our first cluster! Let's first set up a few environment variables to make this process easier.
 ```bash
 export NAME=sq1.k8s.local
 export KOPS_STATE_STORE=s3://bucket-name
```
### CREATE KOPS CLUSTER SINGLE ZONE 
 ```bash
 kops create cluster --zones us-east-1b ${NAME}
 ```

### Suggestions:
 * list clusters with:
```bash
   kops get cluster
```
 * edit this cluster with:
```bash
   kops edit cluster sq1.k8s.local
```
 * edit your node instance group:
```bash   
   kops edit ig --name=sq1.k8s.local nodes-us-east-1b
```
 * edit your control-plane instance group:
```bash 
kops edit ig --name=sq1.k8s.local control-plane-us-east-1b
```
 * Finally configure your cluster with:
```bash
kops update cluster --name sq1.k8s.local --yes --admin
```
 ### DELETE CLUSTER 
 ```bash
 kops delete cluster --name=sq1.k8s.local --state=s3://bucket-name --yes
```

## Source:  
Kops Installation  
https://www.youtube.com/watch?v=f6vv4RkkjG4  
https://github.com/Venkateshd279/Kubernetes/tree/main/Day%202

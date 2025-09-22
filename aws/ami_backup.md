# Backup EC2 Instance to S3 in .VMDK Format
 
This guide explains how to export an EC2 instance and store it as a **VMDK** file in an **S3 bucket**.
 
---
 
## Stop the EC2 Instance
Before exporting, stop the instance. Replace the instance ID with yours.
 
```
aws ec2 stop-instances --instance-ids i-0abcd1234efgh567
 
```
## Create an IAM User
 
```
Open AWS Console → IAM → Users → Add user
 
Enter a username (example: backup-user)
 
Select Programmatic access (CLI access)
 
Attach permissions (we’ll add a custom policy later)
 
Download and store the Access Key ID and Secret Key
 
```
## Create IAM Role for Export
 
```
Go to IAM → Roles → Create Role
```
 
## Choose Custom trust policy and paste:
 
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vmie.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
 
```
Name it something like VMImportExportRole
 
## Attach Policy to Role
Create a custom policy and attach it to the role:
```
 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetBucketAcl"
      ],
      "Resource": [
        "arn:aws:s3:::newtestvmi",
        "arn:aws:s3:::newtestvmi/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:ModifySnapshotAttribute",
        "ec2:CopySnapshot",
        "ec2:RegisterImage",
        "ec2:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
 
```
## Give IAM User Permissions
Edit the inline policy for your IAM user and add:
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateInstanceExportTask",
        "ec2:DescribeInstances",
        "ec2:DescribeExportTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::newtestvmi",
        "arn:aws:s3:::newtestvmi/*"
      ]
    }
  ]
}
 
```
## Create an S3 Bucket
 
```
Go to S3 → Create bucket
 
Example bucket name: newtestvmi
 
Ensure the region matches your EC2 instance region
 
```
## Update Bucket ACL
 
```
Go to S3 → Bucket → Permissions → Access Control List (ACL)
 
Add Read ACP + Write for the AWS export service
 
Add the Region-specific canonical account ID for your region
Example for all region:
```
```
Africa (Cape Town) – 3f7744aeebaf91dd60ab135eb1cf908700c8d2bc9133e61261e6c582be6e33ee
 
Asia Pacific (Hong Kong) – 97ee7ab57cc9b5034f31e107741a968e595c0d7a19ec23330eae8d045a46edfb
 
Asia Pacific (Hyderabad) – 77ab5ec9eac9ade710b7defed37fe0640f93c5eb76ea65a64da49930965f18ca
 
Asia Pacific (Jakarta) – de34aaa6b2875fa3d5086459cb4e03147cf1a9f7d03d82f02bedb991ff3d1df5
 
Asia Pacific (Malaysia) – ed006f67543afcfe0779e356e52d5ed53fa45f95bcd7d277147dfc027aaca0e7
 
Asia Pacific (Melbourne) – 8b8ea36ab97c280aa8558c57a380353ac7712f01f82c21598afbb17e188b9ad5
 
Asia Pacific (New Zealand) – 2dc8fa4ca1c59da5c6a4c5b0e397eea130ec62e49f18cff179034665fd20e8a2
 
Asia Pacific (Osaka) – 40f22ffd22d6db3b71544ed6cd00c8952d8b0a63a87d58d5b074ec60397db8c9
 
Asia Pacific (Taipei) – a9fa0eb7c8483f9558cd14b24d16e9c4d1555261a320b586a3a06908ff0047ce
 
Asia Pacific (Thailand) – d011fe83abcc227a7ac0f914ce411d3630c4ef735e92e88ce0aa796dcfecfbdd
 
Canada West (Calgary) – 78e12f8d798f89502177975c4ccdac686c583765cea2bf06e9b34224e2953c83
 
Europe (Milan) – 04636d9a349e458b0c1cbf1421858b9788b4ec28b066148d4907bb15c52b5b9c
 
Europe (Spain) – 6e81c4c52a37a7f59e103625162ed97bcd0e646593adb107d21310d093151518
 
Europe (Zurich) – 5d9fcea77b2fb3df05fc15c893f212ae1d02adb4b24c13e18586db728a48da67
 
Israel (Tel Aviv) – 328a78de7561501444823ebeb59152eca7cb58fee2fe2e4223c2cdd9f93ae931
 
Mexico (Central) – edaff67fe25d544b855bd0ba9a74a99a2584ab89ceda0a9661bdbeca530d0fca
 
Middle East (Bahrain) – aa763f2cf70006650562c62a09433f04353db3cba6ba6aeb3550fdc8065d3d9f
 
Middle East (UAE) – 7d3018832562b7b6c126f5832211fae90bd3eee3ed3afde192d990690267e475
 
AWS GovCloud (US) – af913ca13efe7a94b88392711f6cfc8aa07c9d1454d4f190a624b126733a5602
 
All other Regions – c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322
 
```
## Start the Export Task
Run the command to start export:
```
aws ec2 create-instance-export-task \
    --description "My EC2 export $(date '+%b %d %H:%M')" \
    --instance-id i-0abcd1234efgh567 \
    --target-environment vmware \
    --export-to-s3-task '{
        "ContainerFormat": "ova",
        "DiskImageFormat": "VMDK",
        "S3Bucket": "newtestvmi",
        "S3Prefix": "vms/"
    }'
```
## Monitor Export Progress
Check the export task status:
```
aws ec2 describe-export-tasks \
    --query "ExportTasks[*].{Description:Description,ExportTaskId:ExportTaskId,State:State,S3Bucket:ExportToS3Task.S3Bucket,InstanceId:InstanceExportDetails.InstanceId}" \
    --output table
```

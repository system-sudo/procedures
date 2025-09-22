# Backup EC2 Instance to S3 in .VMDK Format
## Recommended to follow official Documentation:
```
https://docs.aws.amazon.com/vm-import/latest/userguide/required-permissions.html#vmimport-role
```
 
This guide explains how to export an EC2 instance and store it as a **VMDK** file in an **S3 bucket**.  
Storing EC2 Instance as .vmdk file in S3 is less cost than snapshots.

## Create an S3 Bucket to store the .VMDK backup file
```sh
Go to S3 → Create bucket
 
Example bucket name: ec2instancebackup
Object Ownership : ACLs enabled
Object Ownership : Object writer

Create Bucket
```
## Update Bucket ACL
 
```sh
Go to S3 → Bucket → Permissions → Access Control List (ACL)
 
Add Read ACP + Write for the AWS export service
```
Add the Region-specific canonical account ID for your region
```sh
https://docs.aws.amazon.com/vm-import/latest/userguide/vmexport-prerequisites.html
```
Or Use Common for all canonical account ID:
```sh
All other Regions – c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322 
```
## 1. Stop the EC2 Instance
Before exporting, stop the instance. Replace the instance ID with yours.
```sh
aws ec2 stop-instances --instance-ids i-0abcd1234efgh567
```
## 2. Create IAM Role for Export
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
```
Go to IAM → Roles → Add Permission → Create Inline Policy
```
Create a custom policy INLINE and attach it to the role:
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
## Create a policy for IAM user
```
Go to IAM → policy → Create policy
```
Paste the following in json
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
## Create an IAM User
```
Open AWS Console → IAM → Users → Add user
Enter a username (example: backup-user)
Set permissions → Attach policies directly → Filter by Type (Custom Managed)
```
## Create an Access Key for the IAM User
```
Select Programmatic access (CLI access)
Download and store the Access Key ID and Secret Key
```
## Open a Terminal
Install AWS CLI
To install the AWS CLI, run the following commands.
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Configure AWS
```
aws configure
```
use the above created Access Key of IAM User

## Start the Export Task
Run the command to start export:
```
aws ec2 create-instance-export-task \
    --description "My EC2 export $(date '+%b %d %H:%M')" \
    --instance-id i-0abcd1234efgh567 \
    --target-environment vmware \
    --export-to-s3-task '{
        "DiskImageFormat": "VMDK",
        "S3Bucket": "newtestvmi",
        "S3Prefix": "ec2vmdkbackup/"
    }'
```
## Monitor Export Progress
Check the export task status:
```
aws ec2 describe-export-tasks \
    --query "ExportTasks[*].{Description:Description,ExportTaskId:ExportTaskId,State:State,S3Bucket:ExportToS3Task.S3Bucket,InstanceId:InstanceExportDetails.InstanceId}" \
    --output table
```

#!/bin/bash

# Set the IAM username
IAM_USER_NAME="MyNewUser"

echo "Creating IAM user: $IAM_USER_NAME"
aws iam create-user --user-name "$IAM_USER_NAME"

# List of AWS managed policy ARNs to attach
POLICIES=(
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  "arn:aws:iam::aws:policy/IAMFullAccess"
  "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
)

echo "Attaching policies to user..."
for POLICY_ARN in "${POLICIES[@]}"; do
  echo "Attaching $POLICY_ARN"
  aws iam attach-user-policy --user-name "$IAM_USER_NAME" --policy-arn "$POLICY_ARN"
done
echo "Creating access key for user..."
aws iam create-access-key --user-name "$IAM_USER_NAME"

echo "✅ IAM user '$IAM_USER_NAME' created and configured successfully."

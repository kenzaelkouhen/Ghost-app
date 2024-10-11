#!/bin/bash

# Variables (adjust these as needed)
AWS_ACCOUNT_ID="your_aws_account_id"  # Set this as needed
AWS_REGION="us-east-1"            
ECR_REPO_NAME="ghost-app-repo"
IMAGE_TAG="latest"
DOCKERFILE_PATH="./docker/Dockerfile"

# Connect to your AWS account 
# aws configure 

# Terraform commands
echo "Initializing Terraform..."
terraform init

echo "Planning Terraform changes..."
terraform plan -out=tfplan

echo "Applying Terraform changes..."
terraform apply tfplan

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build the Docker image
echo "Building Docker image..."
docker build -t $ECR_REPO_NAME:$IMAGE_TAG -f $DOCKERFILE_PATH ./src

# Tag the image for ECR
echo "Tagging Docker image..."
docker tag $ECR_REPO_NAME:$IMAGE_TAG ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

# Push the image to ECR
echo "Pushing Docker image to ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

echo "Planning Terraform changes with the image pushed..."
terraform plan -out=tfplan

echo "Applying Terraform changes..."
terraform apply tfplan

echo "Deployment complete."

#!/bin/bash

############ APPLICATION SETTINGS #############
REGION="eu-central-1" # us-west-2   eu-west-2 
APP_NAME="myhelyos"  # Give a name for your app
ENV_NAME="${APP_NAME}-env"

############ RABBITMQ SETTINGS #############
RABBITMQ_BROKER_NAME="${APP_NAME}-rabbitmq"


# Retrieve Default VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --region $REGION \
    --output text)

# Retrieve Default Subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].SubnetId" \
    --region $REGION \
    --output text | tr '\n' ',' | sed 's/,$//')

# Retrieve Default Security Group ID
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?GroupName=='default'].GroupId" \
    --region $REGION \
    --output text)


BROKER_ID=$(aws mq list-brokers --query "BrokerSummaries[?BrokerName=='$RABBITMQ_BROKER_NAME'].BrokerId" --output text --region $REGION)
FULL_RABBITMQ_URL=$(aws mq describe-broker --broker-id $BROKER_ID --query "BrokerInstances[0].Endpoints[0]" --output text --region $REGION)

echo "======= AWS Netork Info ======"
echo "VPC_ID:" $VPC_ID
echo "SUBNET_IDS:" $VPC_ID
echo "SECURITY_GROUP_ID:" $VPC_ID
echo "==============================="

echo "RABBITMQ URL:" $FULL_RABBITMQ_URL

eb status
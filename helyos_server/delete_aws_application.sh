#!/bin/bash

############ APPLICATION SETTINGS #############
REGION="eu-central-1" # us-west-2   eu-west-2 
APP_NAME="myhelyos"  # Give a name for your app
ENV_NAME="${APP_NAME}-env"

############ RABBITMQ SETTINGS #############
RABBITMQ_BROKER_NAME="${APP_NAME}-rabbitmq"

# Prompt user for confirmation before termination
read -p "Are you sure you want to terminate? This will delete all your data from the cloud. (y/n) " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # ============================================================================
    # ============================================================================
    #                      TERMINATE AMAZON MQ RABBITMQ INSTANCE
    # ============================================================================
    # ============================================================================

    echo "Terminating RabbitMQ broker..."

    # Retrieve the Broker ID
    BROKER_ID=$(aws mq list-brokers --query "BrokerSummaries[?BrokerName=='$RABBITMQ_BROKER_NAME'].BrokerId" --output text --region $REGION)

    # Terminate the RabbitMQ broker
    aws mq delete-broker --broker-id $BROKER_ID --region $REGION

    echo "RabbitMQ broker termination initiated..."

    # ============================================================================
    # ============================================================================
    #       TERMINATE THE ELASTIC BEANSTALK ENVIRONMENT AND DELETE APPLICATION
    # ============================================================================
    # ============================================================================

    echo "Terminating Elastic Beanstalk environment..."

    # Terminate the Elastic Beanstalk environment
    eb terminate $ENV_NAME --force --region $REGION

    # Wait for the environment to be terminated
    echo "Waiting for Elastic Beanstalk environment to terminate..."
    aws elasticbeanstalk wait environment-terminated --environment-names $ENV_NAME --region $REGION

    echo "Elastic Beanstalk environment terminated."

    # Delete the Elastic Beanstalk application
    echo "Deleting Elastic Beanstalk application..."
    aws elasticbeanstalk delete-application --application-name $APP_NAME --region $REGION

    echo "Elastic Beanstalk application deleted."

    # Delete the config.yml file if it exists
    [ -f ".elasticbeanstalk/config.yml" ] && rm ".elasticbeanstalk/config.yml"


    echo "All resources have been terminated."
else
    echo "Termination cancelled."
fi
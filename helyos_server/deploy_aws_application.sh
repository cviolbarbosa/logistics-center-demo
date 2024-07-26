#!/bin/bash
############ APPLICATION SETTINGS #############
REGION="eu-central-1" # us-west-2   eu-west-2 
APP_NAME="myhelyos"  # Give a name for your app
ENV_NAME="${APP_NAME}-env"

# Resources - define CPU and memory
EC2_INSTANCE_TYPE="t3.micro"  # for helyOS core
RABBITMQ_INSTANCE_TYPE="mq.t3.micro" # for RabbitMQ broker
DB_CLASS="db.t3.micro"  # for Postgres database


############ RABBITMQ SETTINGS #############
RABBITMQ_BROKER_NAME="${APP_NAME}-rabbitmq"
RABBITMQ_USER="helyosmqadmin"
RABBITMQ_PASSWORD="helyos_mq_secret"

############ DATABASE SETTINGS #############
DB_ENGINE="postgres"
DB_ENGINE_VERSION="13.15"
DB_USERNAME="helyosdbadmin"
DB_PASSWORD="helyos_db_secret"
DB_NAME="autotruck"
DB_ALLOCATED_STORAGE="5"

# Delete the config.yml file if it exists
[ -f ".elasticbeanstalk/config.yml" ] && rm ".elasticbeanstalk/config.yml"

# # ============================================================================
# # ============================================================================
# #                      CREATE AN AMAZON MQ RABBITMQ INSTANCE
# # ============================================================================
# # ============================================================================

echo "Creating RabbitMQ broker..."
aws mq create-broker \
    --broker-name $RABBITMQ_BROKER_NAME \
    --engine-type RabbitMQ \
    --engine-version 3.13 \
    --host-instance-type $RABBITMQ_INSTANCE_TYPE \
    --users Username=$RABBITMQ_USER,Password=$RABBITMQ_PASSWORD \
    --deployment-mode SINGLE_INSTANCE \
    --region $REGION \
    --publicly-accessible 


echo "Waiting for RabbitMQ broker to be available..."
BROKER_ID=$(aws mq list-brokers --query "BrokerSummaries[?BrokerName=='$RABBITMQ_BROKER_NAME'].BrokerId" --output text --region $REGION)
check_broker_status() { aws mq describe-broker --broker-id $BROKER_ID --region $REGION --query "BrokerState" --output text
                      }
WAIT_INTERVAL=10  # Time to wait between status checks, in seconds
while true; do
  STATUS=$(check_broker_status)
  if [ "$STATUS" == "RUNNING" ]; then
    echo "Broker is available."
    break
  else
    echo "Broker status: $STATUS. Waiting..."
    sleep $WAIT_INTERVAL
  fi
done

FULL_RABBITMQ_URL=$(aws mq describe-broker --broker-id $BROKER_ID --query "BrokerInstances[0].Endpoints[0]" --output text --region $REGION)
RABBITMQ_URL=$(echo $FULL_RABBITMQ_URL | sed 's|amqps://||; s|:5671||')
RABBITMQ_PORT=$(echo $FULL_RABBITMQ_URL | sed 's/.*:\([0-9]*\)$/\1/')


# # ============================================================================
# # ============================================================================
# #       DEPLOY THE "DOCKER.COMPOSE.YML" AND CREATE AN AMAZON RDS POSTGRES
# # ============================================================================
# # ============================================================================

## Create Elastic Beanstalk application
aws elasticbeanstalk create-application --application-name $APP_NAME

## Initialize Elastic Beanstalk application with Docker platform
eb init -p docker $APP_NAME --region $REGION

# Define environment variables
ENV_VARS="RBMQ_HOST=$RABBITMQ_URL,\
RBMQ_PORT=$RABBITMQ_PORT,\
RBMQ_API_PORT=15671,\
HELYOS_RBMQ_USERNAME=$RABBITMQ_USER,\
HELYOS_RBMQ_PASSWORD=$RABBITMQ_PASSWORD"    

## Create Elastic Beanstalk environment with RDS instance
echo "Creating Elastic Beanstalk environment and Postgress instance..."
eb create $ENV_NAME \
    --instance_type $EC2_INSTANCE_TYPE \
    --min-instances 1 \
    --max-instances 1 \
    --database.engine $DB_ENGINE \
    --database.version $DB_ENGINE_VERSION \
    --database.size $DB_ALLOCATED_STORAGE \
    --database.instance $DB_CLASS \
    --database.username $DB_USERNAME \
    --database.password $DB_PASSWORD \
    --region $REGION \
    --envvars "$ENV_VARS"


# # Deploy the application
eb deploy --region $REGION









# Deploying helyOS - Yard Automation on AWS Elastic Beanstalk

This tutorial will guide you through deploying the AutoTruck - Yard Automation demonstration, which uses the helyOS framework, on AWS Elastic Beanstalk.

This repository is forked from the AutoTruck project: [helyOSFramework logistics-center-demo](https://github.com/helyOSFramework/logistics-center-demo).


## Prerequisites

- An AWS account.
- AWS CLI installed and configured on your machine.
- Elastic Beanstalk CLI (EB CLI) installed.

## Overview of AutoTruck - Yard Automation

The AutoTruck project automates trucks in logistic centers using helyOS and TruckTrix®. 
This repository is a fork from the original and has been refactored to run on AWS cloud.


## Local Setup

To start the helyOS server locally:

```bash
cd helyos_server
cp .env_local .env
docker-compose -f docker-compose_local up -d
```

Access the dashboard at http://localhost:8080. Default credentials are admin for both username and password.

To start the micoservices:

```bash
cd microservices
docker-compose -f docker-compose_local up -d
```

To open the application:

```bash
cd front-end
docker-compose up -d
```

Access the web app at http://localhost:3080. Default credentials are admin for both username and password.

To restart the vehicle simulator:

```bash
cd simulators
cp .env_local .env
docker-compose up
```

To restart any service:
```bash
docker-compose down -v
docker-compose up
```

Note: The -v flag will delete the database.

## Deploying on AWS Elastic Beanstalk

### Step 1: Install AWS CLI and EB CLI

- Install the AWS CLI following [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- Install the EB CLI following [these instructions](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html).

### Step 2: Prepare Your Application for Deployment

Before deploying your application, ensure that the `.env` file is removed from your project directory to avoid conflicting with the environment variables set via the Elastic Beanstalk service.

### Step 3: Edit Application Settings

Modify the `deploy_aws_application.sh` script with your application name and settings.

### Step 4: Run Deployment Script

Execute the `deploy_aws_application.sh` script. This will:

- Create a RabbitMQ instance and retrieve its URL.
- Deploy the helyOS core services according to `docker-compose.yml`.
- Once helyOS is running, helyOS core will connect and automatically configure the RabbitMQ instance.

### Step 5: Verify Deployment

Wait for the deployment to complete. This can take up to 20 minutes.
You can monitor the progress in the AWS Elastic Beanstalk console.

Run `get_aws_info.sh` to obtain the URLs for your helyOS core and the new RabbitMQ instance.


### Step 6: Configure HTTPS Certificate

You will be able to access the dashboard using the port 443, which will look something like `your_environment_name.xxxxxx.us-west-2.elasticbeanstalk.com:443`. 
If you need to configure a domain name and HTTPS for your application, edit the `.ebextensions/01_load_balancer.config` file to include your SSL certificate ARN:

```yaml
# Listener Configuration
aws:elbv2:listener:443:
  ListenerEnabled: true
  DefaultProcess: Dashboard
  Protocol: HTTP
  Rules: GraphQLRule,WebsocketRule
  # Add a SSLCertificateArns to change to HTTPS
  SSLCertificateArns: <your-ssl-certificate-arn>
```

Replace <your-ssl-certificate-arn> with the ARN of your SSL certificate and add the previous url to the CNAME of your DNS records.
This will enable HTTPS for your custom domain name, ensuring secure communication.



## Conclusion

Congratulations on successfully deploying the AutoTruck - Yard Automation demonstration using the helyOS framework on AWS Elastic Beanstalk.
With the RabbitMQ URL, you can now connect your agents or simulators to the helyOS core, enabling communication and control within your automated yard environment.
Remember that to connect to Amazon MQ RabbitMQ using SSL, you will need the certification authority file, which can be found at [Amazon Trust Services](https://www.amazontrust.com/repository/).


To ensure full functionality of the application, it is essential to deploy the associated microservices. 
You have the option to create an additional Elastic Beanstalk application for the microservices or to deploy them as AWS Lambda functions, depending on your preference and the requirements of your project.

 For more information on the original implementation, visit the [helyOSFramework logistics-center-demo](https://github.com/helyOSFramework/logistics-center-demo).


#!/bin/bash

# default local and AWS secrets, placeholders only - safe to commit to git
# be sure that all values are defined in setup_auto.sh or in setup_user.sh


# AWS IAM ----------------------------------------------------------------------

# AWS Access Key ID (simplest setup: create a deployment user/key)
# AWS > IAM > Users > Add user
# (we use the IAM_ prefix to avoid exporting it locally by mistake)
# Might be different than what is in AWS profile; will be used on EC2
# If you use the came access on both local and EC2, copy from AWS CLI profile
IAM_ACCESS_KEY_ID="$MISSING"

# Secret Access Key corresponding to Access Key ID
# Only available when the user has been created
# If you use the came access on both local and EC2, copy from AWS CLI profile
IAM_SECRET_ACCESS_KEY="$MISSING"


# AWS EC2 ----------------------------------------------------------------------

# The name (as known to AWS) of the SSH key used to connect to an EC2 instance securely
# A file with the same name (and with extension .pem) should have been downloaded 
# from AWS to the dir ~/.ssh/
# AWS > EC2 > Network and security > Key Pairs > Create Key Pair
EC2_KEY_NAME="$MISSING"

# The dir where the above key file is located
EC2_KEY_FILE="~/.ssh/${EC2_KEY_NAME}.pem"

# AWS > VPC > Subnets > (optional: Create Subnet)
# If no VPC setup, see AWS > VPC > Your VPCs > Create VPC
EC2_SUBNET_ID="subnet-$MISSING"

# The security group id to which the new instance will belong
# AWS > EC2 > Network a& Security > Security Groups > Create Security Group
EC2_SECURITY_GROUP_IDS="sg-$MISSING"


## AWS S3 ----------------------------------------------------------------------

# The name of the S3 bucket in which the deployment package will be uploaded
# AWS > S3 > (optional: Create bucket & folder)
S3_BUCKET="$MISSING"


# AWS API Gateway --------------------------------------------------------------

# The AWS name of the API Gateway on which the http calls are made 
# AWS > API Gateway > API's
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_GATEWAY_NAME="$MISSING"

# Obtained automatically from API_GATEWAY_NAME, listed here for reference
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_GATEWAY_ID="$MISSING"

# The AWS name of the resource under the API Gateway Root Resource
# AWS > API Gateway > APIs > [API NAME] > Resources
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_RESOURCE_NAME="$MISSING"

# Obtained automatically from API_RESOURCE_NAME, listed here for reference
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_RESOURCE_ID="$MISSING"

# The AWS name of the Alias resource (e.g. url of the latest app API version)
# Ignored if $API_ALIAS_RESOURCE == "false"
# AWS > API Gateway > APIs > [API NAME] > Resources
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_ALIAS_RESOURCE_NAME="$MISSING"

# Obtained automatically from API_ALIAS_RESOURCE_NAME, listed here for reference
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_ALIAS_RESOURCE_ID="$MISSING"

# The AWS name of API custom authorizer (that calls Lambda Authorizer)
# AWS > API Gateway > APIs > [API NAME] > Authorizers
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_AUTHORIZER_NAME="$MISSING"

# Obtained automatically from API_AUTHORIZER_NAME, listed here for reference
# Added in `setup_auto.sh` by `24_setup_lambda.sh`
API_AUTHORIZER_ID="$MISSING"

# Authorization token for the Lambda Authorizer function 
# Needed to make API requests (to restrict access to the main Lambda function)
# Must match API_TOKEN in lambda_authorizer.js
# AWS> LAMBDA > see code within the lambda authorization function
API_TOKEN="aws-lambda-r-api-token"


## AWS Lambda ------------------------------------------------------------------

# The AWS name of the Lambda function (in Python, calling R)
# If missing, "${PRJ_NAME}-${PRJ_BRANCH}-${API_STAGE}-${API_RESOURCE_NAME}"
# AWS > Lambda > Functions
LAMBDA_FUNCTION_NAME="$MISSING"

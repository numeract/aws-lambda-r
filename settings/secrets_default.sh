#!/bin/bash

# default local and AWS secrets, placeholders only - safe to commit to git
# be sure that all values are defined in setup_auto.sh or in setup_user.sh


# AWS IAM ----------------------------------------------------------------------

# AWS Access Key ID (simplest setup: create a deployment user/key)
# AWS > IAM > Users > Add user
# (we use the IAM_ prefix to avoid exporting it locally by mistake)
# Copy from AWS CLI profile
IAM_ACCESS_KEY_ID="$MISSING"

# Secret Access Key corresponding to Access Key ID
# Only available when the user has been created
# Copy from AWS CLI profile
IAM_SECRET_ACCESS_KEY="$MISSING"

# The ARN of the AWS Role associated with the lambda function
# AWS > IAM > Roles > (optional: Create new role)
IAM_LAMBDA_FUNCTION_ROLE="arn:aws:iam::$MISSING:role/$MISSING"


# AWS EC2 ----------------------------------------------------------------------

# The name (as known to AWS) of the SSH key used to connect to an EC2 instance securely
# A file with the same name (and with extension .pem) should have been downloaded 
# from AWS to the dir ~/.ssh/
# AWS > EC2 > Network and security > Key Pairs > Create Key Pair
EC2_KEY_NAME="$MISSING"

# The dir where the above key file is located
EC2_KEY_FILE="~/.ssh/$EC2_KEY_NAME.pem"

# AWS > VPC > Subnets > (optional: Create Subnet)
# If no VPC setup, see AWS > VPC > Your VPCs > Create VPC
EC2_SUBNET_ID="subnet-$MISSING"

# The security group id to which the new instance will belong
# AWS > EC2 > Network a& Security > Security Groups > Create Security Group
EC2_SECURITY_GROUP_IDS="sg-$MISSING"


## AWS S3 ----------------------------------------------------------------------

# The name of the s3 bucket in which the deployment package will be uploaded
# AWS > S3 > (optional: Create bucket & folder)
S3_BUCKET="$MISSING"


## AWS Lambda ------------------------------------------------------------------


# AWS API Gateway --------------------------------------------------------------

# The ID of the API gateway on which the http calls are made 
# AWS > API Gateway > API's ??
API_ID="$MISSING"

# The ID of the resource under the API Gateway
# AWS > API Gateway > APIs > [API NAME] > Resources
API_RESOURCE_ID="$MISSING"

# The ID of the resource containing the latest version of the API
# AWS > API Gateway > APIs > [API NAME] > Resources
API_ALIAS_RESOURCE_ID="$MISSING"

# The ID of the custom authorizer used by the API's http method 
# AWS > API Gateway > APIs > [API NAME] > Authorizers
API_AUTHORIZER_ID="$MISSING"

# Authorization token used in order to make API requests
# AWS> LAMBDA > Lambda authorization function
API_TOKEN="$MISSING"

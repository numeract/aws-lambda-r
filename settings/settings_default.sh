#!/bin/bash

# default local and AWS settings, excluding secrets - safe to commit to git
# be sure that all values are defined in setup_auto.sh or in setup_user.sh


# Project ----------------------------------------------------------------------

# name of the project root directory, error if mismatch
# use only letters, dashes, and digits, e.g. aws-lambda-r
PRJ_NAME="$MISSING"

# Name of the current Git branch, error if mismatch
PRJ_BRANCH="$MISSING"


# AWS --------------------------------------------------------------------------

# We do not set AWS_PROFILE to prevent undesired interactions with AWS CLI
# profile to use for AWS as in `aws $AWS_PRFL s3 ls`
AWS_PRFL="--profile default"

# We do not set AWS_DEFAULT_REGION to prevent undesired interactions with AWS CLI
# AWS ec2, s3, lambda and API gateway region. us-east-1 is US East (N. Virginia).
AWS_REGION="us-east-1"


# AWS EC2 ----------------------------------------------------------------------

# The ID of the Amazon Machine Image which is the template for the EC2 instance.
# Find the most recent AMI used by AWS Lambda for your region
# https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html
EC2_DEFAULT_AMI_ID="ami-4fffc834"

# The ID of the cache AMI ($EC2_AMI_ID + update + python + R)
# If present this ID will be used instead of $EC2_AMI_ID
# Usually kept private because it is project specific and may contain your keys
# Added automatically in setup_auto.sh by 
EC2_CUSTOM_AMI_ID="$MISSING"

# The type/size of the instance 
# AWS > EC2 > instance-types
EC2_INSTANCE_TYPE="t2.micro"

# For Amazon Linux VMs the default username is 'ec2-user'.
EC2_USERNAME="ec2-user"

# Maximum number of attempts to check on the EC2. Each attempt takes 5 seconds.
EC2_MAX_TESTS=20


## AWS Lambda ------------------------------------------------------------------

# The name of the python file which contains the lambda function (w/o extension)
# AWS > Lambda > Functions > Configuration
LAMBDA_PYTHON_HANDLER="lambda_post"

# The name of the handler function within the LAMBDA_PYTHON_HANDLER 
# AWS > Lambda > Functions > Configuration
LAMBDA_HANDLER_FUNCTION="handler_post"

# The chosen runtime for lambda function (AWS>LAMBDA>RUNTIME)
# AWS > Lambda > Functions > Configuration
LAMBDA_RUNTIME="python3.6"

# The time limit (in seconds) for the lambda function to run
# AWS > Lambda > Functions > Configuration
LAMBDA_TIMEOUT="59"

# The amount of memory allocated to the lambda function (max memory --> max CPU)
# AWS > Lambda > Functions > Configuration
LAMBDA_MEMORY_SIZE="3008"


# AWS API Gateway --------------------------------------------------------------

# A stage is a unique identifier for a version of a deployed API
# Choices (suggested): alpha, beta, prod
API_STAGE="alpha"

# The type of request API is expecting 
API_HTTP_METHOD="POST"

# The type of API gateway authorization. In order to secure API calls 
API_AUTHORIZATION_TYPE="CUSTOM"


# R ----------------------------------------------------------------------------

# List of R packages to be installed and used by the Lambda function
# do not use commas or quotes, leave spaces before and after each package name
R_PACKAGES=( jsonlite )


# testing ----------------------------------------------------------------------

# Option for cp command.
# Choices: "--verbose" (show the copied files) or " " (copy without showing) 
CP_VERBOSE=" "

# set to "skip_commit" to skip commit (unsafe!)
DEBUG="false"

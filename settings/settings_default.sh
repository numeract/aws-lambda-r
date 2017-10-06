#!/bin/bash

# default local and AWS settings, excluding secrets - safe to commit to git


# Project ----------------------------------------------------------------------

# name of the project root directory, error if mismatch
PRJ_NAME="aws-lambda-r"

# Name of the current Git branch, error if mismatch
PRJ_BRANCH="dev"

# set to "skip_commit" to skip commit (unsafe!)
# DEBUG="false"


# AWS --------------------------------------------------------------------------

# profile to use for AWS as in `aws $AWS_PRFL s3 ls`
AWS_PRFL="--profile default"

# AWS ec2, s3, lambda and API gateway region. eu-central-1 is Frankfurt.
AWS_REGION="eu-central-1"


# AWS EC2 ----------------------------------------------------------------------

# The id of the Amazon Machine Image which is the template for the EC2 instance.
# AWS > amazon-linux-ami > Amazon Linux AMI IDs
# EC2_AMI_ID="ami-657bd20a"
EC2_AMI_ID="ami-73e5521c"

# The type/size of the instance 
# AWS > EC2 > instance-types
EC2_INSTANCE_TYPE="t2.micro"

# For Amazon Linux VMs the default username is 'ec2-user'.
EC2_USERNAME="ec2-user"

# Maximum number of attempts to check on the EC2. Each attempt takes 5 seconds.
EC2_MAX_TESTS=24


## AWS Lambda ------------------------------------------------------------------

# The name of the python file which contains the lambda function
# AWS > Lambda > Functions > Configuration
LAMBDA_PYTHON_HANDLER="lambda_post"

# The name of the handler function within the LAMBDA_PYTHON_HANDLER 
# AWS > Lambda > Functions > Configuration
LAMBDA_HANDLER_FUNCTION="handler_post"

# The chosen runtime for lambda function (AWS>LAMBDA>RUNTIME)
# AWS > Lambda > Functions > Configuration
LAMBDA_RUNTIME="python2.7"

# The time limit (in seconds) for the lambda function to run
# AWS > Lambda > Functions > Configuration
LAMBDA_TIMEOUT="59"

# The amount of memory allocated to the lambda function (max memory --> max CPU)
# AWS > Lambda > Functions > Configuration
LAMBDA_MEMORY_SIZE="1536"


# AWS API Gateway --------------------------------------------------------------

# A stage is a unique identifier for a version of a deployed API
# Choices (suggested): alpha, beta, prod
API_STAGE="alpha"

# The type of request API is expecting 
API_HTTP_METHOD="POST"

# The type of API gateway authorization. In order to secure API calls 
API_AUTHORIZATION_TYPE="CUSTOM"


# testing ----------------------------------------------------------------------

# The session_id from the database 
SESSION_ID="5575764"

# Option for cp command.
# Choices: "--verbose" (show the copied files) or " " (copy without showing) 
CP_VERBOSE=" "

# List of R packages to be installed and used by the Lambda function
# do not use commas or quotes, leave spaces before and after each package name
R_PACKAGES=( purrr signal pracma geosphere DBI RMySQL jsonlite digest )


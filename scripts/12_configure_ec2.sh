#!/bin/bash

# run on EC2, configures EC2

# Assume colors variables and functions defined before settings files
# All 4 settings scripts were called before calling this script
# We have access to all the settings as on the local machine,
# we need to reproduce some of `02_setup.sh` functionality


# on EC2 we need to connect to other AWS service (S3, Lambda, API Gateway, ...)
# to simplify use of AWS CLI on EC2 we will create AWS config files
echo -e "$INFO Configure AWS on EC2"
sudo mkdir -p ~/.aws
echo -en \
    "[default]\n" \
    "output = json\n" \
    "region = ${AWS_REGION}\n" \
    | sed -e 's/^[ ]*//' | sudo tee ~/.aws/config > /dev/null
echo -en \
    "[default]\n" \
    "aws_access_key_id = ${IAM_ACCESS_KEY_ID}\n" \
    "aws_secret_access_key = ${IAM_SECRET_ACCESS_KEY}\n" \
    "region = ${AWS_REGION}\n" \
    | sed -e 's/^[ ]*//' | sudo tee ~/.aws/credentials > /dev/null


# does AWS CLI work on EC2? Also get AWS Account ID on EC2 (used to create ARNs)
echo -e "$INFO Check AWS configuration on EC2 ..."
AWS_ACCOUNT_ID="$(aws sts get-caller-identity \
    --query "Account" \
    --output text)"
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo -e "$ERROR Failed to obtain AWS Account ID on EC2." \
        "Is AWS CLI configured? Exiting."
        exit 1
else
    echo -e "$INFO AWS Account ID:" \
        "$(FC "********$(printf $AWS_ACCOUNT_ID | tail -c 4)")"
fi


# arbitrary AWS Lambda function name
# must match `02_setup.sh` definition
if [[ $LAMBDA_FUNCTION_NAME == "$MISSING" ]]; then
    LAMBDA_FUNCTION_NAME="${PRJ_NAME}-${PRJ_BRANCH}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_STAGE}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_RESOURCE_NAME}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_HTTP_METHOD}"
    LAMBDA_FUNCTION_NAME="$(echo ${LAMBDA_FUNCTION_NAME} | tr '[A-Z]' '[a-z]')"
    LAMBDA_FUNCTION_NAME="$(echo ${LAMBDA_FUNCTION_NAME} | tr '/' '-')"
fi
echo -e "$INFO Lambda Function Name: $(FC $LAMBDA_FUNCTION_NAME)"


# use the right lambda given api method
# must match `02_setup.sh` definition
if [[ $API_HTTP_METHOD == "GET" ]]; then
    LAMBDA_PYTHON_HANDLER="$LAMBDA_PYTHON_HANDLER_GET"
    LAMBDA_HANDLER_FUNCTION="$LAMBDA_HANDLER_FUNCTION_GET"
fi
if [[ $API_HTTP_METHOD == "POST" ]]; then
    LAMBDA_PYTHON_HANDLER="$LAMBDA_PYTHON_HANDLER_POST"
    LAMBDA_HANDLER_FUNCTION="$LAMBDA_HANDLER_FUNCTION_POST"
fi


# automatically stop script when a command fails
set -e

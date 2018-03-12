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
    "region = ${AWS_REGION}\n" | \
    sudo tee ~/.aws/config
echo -en \
    "[default]\n" \
    "aws_access_key_id = ${IAM_ACCESS_KEY_ID}\n" \
    "aws_secret_access_key = ${IAM_SECRET_ACCESS_KEY}\n" \
    "region = ${AWS_REGION}\n" | \
    sudo tee ~/.aws/credentials

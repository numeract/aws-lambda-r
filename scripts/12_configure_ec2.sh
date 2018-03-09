#!/bin/bash

# run on EC2, configure EC2


# All 4 settings scripts were called before calling this scrip
# We have access to all the settings as on the local machine


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

#!/bin/bash

# run on EC2 to configure it


# variable & functions to display messages
INFO="\e[32mINFO :\e[39m"                               # Green
WARN="\e[33mWARN :\e[39m"                               # Yellow
ERROR="\e[31mERROR:\e[39m"                              # Red
MISSING="\e[95mMISSING\e[39m"                           # Magenta

FY () { echo -e "\e[33m$1\e[39m"; }                     # Foreground Yellow
FC () { echo -e "\e[36m$1\e[39m"; }                     # Foreground Cyan
BY () { echo -e "\e[43m\e[30m$1\e[39m\e[49m"; }         # Background Yellow


# create AWS config files
echo -e "$INFO Configure AWS on EC2"
sudo mkdir -p ~/.aws
echo -en "[default]\noutput = json\nregion = ${AWS_REGION}\n" | sudo tee ~/.aws/config
echo -en "[default]\naws_access_key_id = ${IAM_ACCESS_KEY_ID}\naws_secret_access_key =" \
         "${IAM_SECRET_ACCESS_KEY}\nregion = ${AWS_REGION}\n" | sudo tee ~/.aws/credentials


# The Name of the resource under the API Gateway
API_RESOURCE_NAME="$(aws apigateway get-resource \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --query "pathPart" \
    --output text)"
echo -e "$INFO API_RESOURCE_NAME: $(FC $API_RESOURCE_NAME)"

# The Name of the resource alias under the API Gateway
API_ALIAS_RESOURCE_NAME="$(aws apigateway get-resource \
    --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --query "pathPart" \
    --output text)"
echo -e "$INFO API_ALIAS_RESOURCE_NAME: $(FC $API_ALIAS_RESOURCE_NAME)"


# arbitrary AWS Lambda function name - defined here too, to be available on EC2
LAMBDA_FUNCTION_NAME="${PRJ_NAME}-${PRJ_BRANCH}-${API_STAGE}-${API_RESOURCE_NAME}"
LAMBDA_ZIP="${LAMBDA_FUNCTION_NAME}.zip"
echo -e "$INFO LAMBDA_FUNCTION_NAME: $(FC $LAMBDA_FUNCTION_NAME)"

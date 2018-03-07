#!/bin/bash

# check if Lambda exists given the config variables, create it if not


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# Settings for setup  ---------------------------------------------------------

# The name of role assigned to lambda function
LAMBDA_ROLE_NAME="${PRJ_NAME}-lambda-role"

# The name of the file containing trust policy
LAMBDA_ROLE_TRUST_FILE="lambda_role_trust.json"

# The name of the file containing role policy
LAMBDA_ROLE_POLICY_FILE="lambda_role_policy.json"

# The name of policy assigned to lambda role
POLICY_NAME="${PRJ_NAME}-lambda-policy"

# The name of the Lambda authorizer function
LAMBDA_AUTHORIZER_NAME="${PRJ_NAME}-LambdaAuthorizer"

# API Gateway Name
API_GATEWAY_NAME="${PRJ_NAME}-API"

# Name of resource under API root resource 
API_RESOURCE_NAME="${PRJ_NAME}_res"

API_ALIAS_RESOURCE_NAME="${PRJ_NAME}_alias_res"

# Name of API custom authorizer
AUTHORIZER_NAME="Authorizer"









#API_ROLE_NAME="tutorial_api_role"

# TODO: consider colors similar to 02_setup.sh

# Create the role and attach the trust policy that enables EC2 to assume this role.
aws $AWS_PRFL iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document file://../doc/$LAMBDA_ROLE_TRUST_FILE \
    --output table

# Attach inline policy to role
aws $AWS_PRFL iam put-role-policy \
    --role-name $LAMBDA_ROLE_NAME  \
    --policy-name $POLICY_NAME \
    --policy-document file://../doc/$LAMBDA_ROLE_POLICY_FILE

LAMBDA_ROLE_ARN="$(aws iam get-role \
    --role-name $LAMBDA_ROLE_NAME \
    --query Role.Arn \
    --output text)"



# Creating role for API 
API_ROLE_NAME="${PRJ_NAME}-api-role"


API_ROLE_ARN=""



# Creating Lambda Authorizer Function
 
sleep 10
echo -e "$INFO Creating lambda function."
aws $AWS_PRFL lambda create-function \
    --region ${AWS_REGION} \
    --function-name ${LAMBDA_AUTHORIZER_NAME} \
    --zip-file fileb://../doc/index.zip \
    --role ${LAMBDA_ROLE_ARN} \
    --handler index.handler \
    --runtime nodejs6.10 \
    --output table

# Extracting the lambda function ARN

LAMBDA_AUTHORIZER_ARN="$(aws $AWS_PRFL lambda list-functions \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionArn" \
    --output text \
    --region ${AWS_REGION})"


# Creating API
aws $AWS_PRFL apigateway create-rest-api \
    --name $API_GATEWAY_NAME \
    --output table

# Getting API id
API_ID="$(aws $AWS_PRFL apigateway get-rest-apis \
    --query "items[?name==\`${API_GATEWAY_NAME}\`].id" \
    --output text)"



# Getting API root resource id

ROOT_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/\`].id" \
    --output text)"
                    


# Creating Resource

aws $AWS_PRFL apigateway create-resource \
    --rest-api-id ${API_ID} \
    --parent-id ${ROOT_RESOURCE_ID} \
    --path-part ${API_RESOURCE_NAME} \
    --output table

API_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/${API_RESOURCE_NAME}\`].id" \
    --output text)"

# Creating Alias Resource
aws $AWS_PRFL apigateway create-resource \
    --rest-api-id ${API_ID} \
    --parent-id ${ROOT_RESOURCE_ID} \
    --path-part ${API_ALIAS_RESOURCE_NAME} \
    --output table

API_ALIAS_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/${API_ALIAS_RESOURCE_NAME}\`].id" \
    --output text)"

# Creating Authorizer
aws $AWS_PRFL apigateway create-authorizer 
    --rest-api-id ${API_ID} \
    --name ${AUTHORIZER_NAME} \
    --type TOKEN --authorizer-uri 'arn:aws:apigateway:'${AWS_REGION}':lambda:path/2015-03-31/functions/'${LAMBDA_AUTHORIZER_ARN}'/invocations' \
    --identity-source 'method.request.header.Auth' \
    --authorizer-result-ttl-in-seconds 300 \
    --output table
                                 

AUTHORIZER_ID="$(aws $AWS_PRFL apigateway get-authorizers \
    --rest-api-id ${API_ID} \
    --query "items[?name==\`${AUTHORIZER_NAME}\`].id" \
    --output text)"                              

API_ARN=$(echo ${LAMBDA_AUTHORIZER_ARN} | \
    sed -e 's/lambda/execute-api/' \
    -e "s/function:${LAMBDA_AUTHORIZER_NAME}/${API_ID}/")
 
# Adding permissions for authorizer invocation 
aws $AWS_PRFL lambda add-permission \
    --function-name ${LAMBDA_AUTHORIZER_ARN} \
    --source-arn ${API_ARN}/authorizers/${AUTHORIZER_ID} \
    --principal apigateway.amazonaws.com \
    --statement-id ${PRJ_NAME}_stmt \
    --action lambda:InvokeFunction
           
# Adding permissions for API logging (?)


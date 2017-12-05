#/!bin/bash

# variable & functions to display messages
INFO="\e[32mINFO :\e[39m"                               # Green
WARN="\e[33mWARN :\e[39m"                               # Yellow
ERROR="\e[31mERROR:\e[39m"                              # Red
MISSING="\e[95mMISSING\e[39m"                           # Magenta

FY () { echo -e "\e[33m$1\e[39m"; }                     # Foreground Yellow
FC () { echo -e "\e[36m$1\e[39m"; }                     # Foreground Cyan
BY () { echo -e "\e[43m\e[30m$1\e[39m\e[49m"; }         # Background Yellow

source "../settings/settings_default.sh"

#API_ROLE_NAME="tutorial_api_role"

# TODO: consider colors similar to 02_setup.sh
# TODO: must use AWS profiles

# Create the role and attach the trust policy that enables EC2 to assume this role.
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document file://../doc/$LAMBDA_ROLE_TRUST_FILE \
    --output table

# Attach inline policy to role
aws iam put-role-policy \
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

# Creating S3 Bucket
aws s3api create-bucket --bucket ${S3_BUCKET} \
                        --region ${AWS_REGION} \
                        --create-bucket-configuration LocationConstraint=${AWS_REGION}



# Creating Lambda Authozizer Function
 
sleep 10
echo -e "$INFO Creating lambda function."
aws lambda create-function \
    --region ${AWS_REGION} \
    --function-name ${LAMBDA_AUTHORIZER_NAME} \
    --zip-file fileb://../doc/index.zip \
    --role ${LAMBDA_ROLE_ARN} \
    --handler index.handler \
    --runtime nodejs6.10 \
    --output table

# Extracting the lambda function ARN

LAMBDA_AUTHORIZER_ARN="$(aws lambda list-functions \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionArn" \
    --output text \
    --region ${AWS_REGION})"


# Creating API
aws apigateway create-rest-api --name $API_GATEWAY_NAME --output table

# Getting API id
API_ID="$(aws apigateway get-rest-apis \
        --query "items[?name==\`${API_GATEWAY_NAME}\`].id" \
        --output text)"



# Getting API root resource id

ROOT_RESOURCE_ID="$(aws apigateway get-resources \
                    --rest-api-id ${API_ID} \
                    --query "items[?path==\`/\`].id" \
                    --output text)"
                    


# Creating Resource

aws apigateway create-resource \
            --rest-api-id ${API_ID} \
            --parent-id ${ROOT_RESOURCE_ID} \
            --path-part ${API_RESOURCE_NAME} \
            --output table

API_RESOURCE_ID="$(aws apigateway get-resources \
                --rest-api-id ${API_ID} \
                --query "items[?path==\`/${API_RESOURCE_NAME}\`].id" \
                --output text)"
                
# Creating alias resource
aws apigateway create-resource \
            --rest-api-id ${API_ID} \
            --parent-id ${ROOT_RESOURCE_ID} \
            --path-part ${API_ALIAS_RESOURCE_NAME} \
            --output table

API_ALIAS_RESOURCE_ID="$(aws apigateway get-resources \
                --rest-api-id ${API_ID} \
                --query "items[?path==\`/${API_ALIAS_RESOURCE_NAME}\`].id" \
                --output text)"


# Creating Authorizer
aws apigateway create-authorizer --rest-api-id ${API_ID} \
                                 --name ${AUTHORIZER_NAME} \
                                 --type TOKEN --authorizer-uri 'arn:aws:apigateway:'${AWS_REGION}':lambda:path/2015-03-31/functions/'${LAMBDA_AUTHORIZER_ARN}'/invocations' \
                                 --identity-source 'method.request.header.Auth' \
                                 --authorizer-result-ttl-in-seconds 300 \
                                 --output table
                                 

AUTHORIZER_ID="$(aws apigateway get-authorizers \
                   --rest-api-id ${API_ID} \
                   --query "items[?name==\`${AUTHORIZER_NAME}\`].id" \
                   --output text)"                              

API_ARN=$(echo ${LAMBDA_AUTHORIZER_ARN} | \
    sed -e 's/lambda/execute-api/' \
    -e "s/function:${LAMBDA_AUTHORIZER_NAME}/${API_ID}/")
 
# Adding permissions for authorizer invocation 
aws lambda add-permission \
           --function-name ${LAMBDA_AUTHORIZER_ARN} \
           --source-arn ${API_ARN}/authorizers/${AUTHORIZER_ID} \
           --principal apigateway.amazonaws.com \
           --statement-id ${PRJ_NAME}_stmt \
           --action lambda:InvokeFunction
           
# Adding permissions for API logging

# Writing variables in default_setup.sh
echo -en "IAM_LAMBDA_FUNCTION_ROLE=${LAMBDA_ROLE_ARN}\nAPI_ID=${API_ID}" \
         "\nAPI_AUTHORIZER_ID=${AUTHORIZER_ID}\n" \
         "API_ARN=${API_ARN}\nAPI_RESOURCE_ID=${API_RESOURCE_ID}"\
         "\nAPI_ALIAS_RESOURCE_ID=${API_ALIAS_RESOURCE_ID}"\
         "\nS3_BUCKET=${S3_BUCKET}\n"|  tee ../settings/default_setup.sh

echo -e "$INFO Lambda role ARN is: $(FY $LAMBDA_ROLE_ARN) "
echo -e "$INFO LAMBDA_AUTHORIZER_ARN is: $(FY $LAMBDA_AUTHORIZER_ARN)"
echo -e "$INFO API ID is: $(FY $API_ID)"
echo -e "$INFO API ROOT_RESOURCE_ID is: $(FY $ROOT_RESOURCE_ID)"
echo -e "$INFO API_RESOURCE_ID is: $(FY $API_RESOURCE_ID) "
echo -e "$INFO API_ALIAS_RESOURCE_ID is: $(FY $API_ALIAS_RESOURCE_ID) "
echo -e "$INFO AUTHORIZER_ID is: $(FY $AUTHORIZER_ID)"
echo -e "$INFO API_ARN is: $(FY $API_ARN)"
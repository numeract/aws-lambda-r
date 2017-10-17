#/!bin/bash

# Create lambda roles

PRJ_NAME="aws-lambda-r"

LAMBDA_ROLE_NAME="${PRJ_NAME}-lambda-role"
LAMBDA_ROLE_TRUST_FILE="lambda_role_trust.json"
LAMBDA_ROLE_POLICY_FILE="lambda_role_policy.json"
POLICY_NAME="${PRJ_NAME}-lambda-policy"
AWS_REGION="eu-west-1"
LAMBDA_AUTHORIZER_NAME="${PRJ_NAME}-LambdaAuthorizer"
S3_BUCKET="${PRJ_NAME}-bucket"
API_GATEWAY_NAME="${PRJ_NAME}-API"
API_RESOURCE_NAME="${PRJ_NAME}_res"
AUTHORIZER_NAME="Authorizer"

#API_ROLE_NAME="tutorial_api_role"

# TODO: consider colors similar to 02_setup.sh
# TODO: must use AWS profiles

# Create the role and attach the trust policy that enables EC2 to assume this role.
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document file://$LAMBDA_ROLE_TRUST_FILE

# Attach inline policy to role
aws iam put-role-policy \
    --role-name $LAMBDA_ROLE_NAME  \
    --policy-name $POLICY_NAME \
    --policy-document file://$LAMBDA_ROLE_POLICY_FILE

LAMBDA_ROLE_ARN="$(aws iam get-role \
    --role-name $LAMBDA_ROLE_NAME \
    --query Role.Arn \
    --output text)"


echo -e "Lambda role ARN is: ${LAMBDA_ROLE_ARN}"

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
    --zip-file fileb://index.zip \
    --role ${LAMBDA_ROLE_ARN} \
    --handler index.handler \
    --runtime nodejs6.10 \
    --output table

# Extracting the lambda function ARN

LAMBDA_AUTHORIZER_ARN="$(aws lambda list-functions \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionArn" \
    --output text \
    --region ${AWS_REGION})"
echo -e "LAMBDA_AUTHORIZER_ARN: $LAMBDA_AUTHORIZER_ARN"

# Creating API

aws apigateway create-rest-api --name $API_GATEWAY_NAME

# Getting API id
API_ID="$(aws apigateway get-rest-apis \
        --query "items[?name==\`${API_GATEWAY_NAME}\`].id" \
        --output text)"

echo "API ID is ${API_ID}"

# Getting API root resource id

ROOT_RESOURCE_ID="$(aws apigateway get-resources \
                    --rest-api-id ${API_ID} \
                    --query "items[?path==\`/\`].id" \
                    --output text)"
                    
echo "API ROOT_RESOURCE_ID is ${ROOT_RESOURCE_ID}"

# Creating Resource

aws apigateway create-resource \
            --rest-api-id ${API_ID} \
            --parent-id ${ROOT_RESOURCE_ID} \
            --path-part ${API_RESOURCE_NAME}

API_RESOURCE_ID="$(aws apigateway get-resources \
                --rest-api-id ${API_ID} \
                --query "items[?path==\`${API_RESOURCE_NAME}\`].id" \
                --output text)"



# Creating Authorizer
aws apigateway create-authorizer --rest-api-id ${API_ID} \
                                 --name ${AUTHORIZER_NAME} \
                                 --type TOKEN --authorizer-uri 'arn:aws:apigateway:'${AWS_REGION}':lambda:path/2015-03-31/functions/'${LAMBDA_AUTHORIZER_ARN}'/invocations' \
                                 --identity-source 'method.request.header.Auth' \
                                 --authorizer-result-ttl-in-seconds 300
                                 

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
           
# Adding permissions for  logging



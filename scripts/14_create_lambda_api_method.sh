#!/bin/bash


echo -e "$INFO Uploading deployment package to S3"
LAMBDA_ZIP_NAME="${LAMBDA_FUNCTION_NAME}.zip"
aws s3 cp ~/${LAMBDA_ZIP_NAME} s3://${S3_BUCKET}/lambda/


# Delete lambda function if already exists
LAMBDA_FUNCTION_NAME_OLD=$(aws lambda list-functions \
    --region $AWS_REGION \
    --query "Functions[?FunctionName==\`${LAMBDA_FUNCTION_NAME}\`].FunctionName" \
    --output text)
if [[ "$LAMBDA_FUNCTION_NAME_OLD" == "$LAMBDA_FUNCTION_NAME" ]]; then
    echo -e "$INFO Deleting previous Lambda Function $(FC $LAMBDA_FUNCTION_NAME)"
    aws lambda delete-function \
        --function-name $LAMBDA_FUNCTION_NAME \
        --output table
fi


# Create lambda function
echo -e "$INFO Creating Lambda Function $(FC $LAMBDA_FUNCTION_NAME)"
aws lambda create-function \
    --region $AWS_REGION \
    --function-name $LAMBDA_FUNCTION_NAME \
    --code "S3Bucket=${S3_BUCKET},S3Key=lambda/${LAMBDA_ZIP_NAME}" \
    --role $IAM_LAMBDA_ROLE_ARN \
    --handler "${LAMBDA_PYTHON_HANDLER}.${LAMBDA_HANDLER_FUNCTION}" \
    --runtime $LAMBDA_RUNTIME \
    --environment Variables="{R_HOME=/var/task/bin,R_LIBS=/lib/}" \
    --timeout $LAMBDA_TIMEOUT \
    --memory-size $LAMBDA_MEMORY_SIZE \
    --output table
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    # Extracting the lambda function ARN
    LAMBDA_ARN=$(aws lambda list-functions \
                 --region $AWS_REGION \
                 --query "Functions[?FunctionName==\`${LAMBDA_FUNCTION_NAME}\`].FunctionArn" \
                 --output text)
    echo -e "$INFO LAMBDA_ARN is: $(FY $LAMBDA_ARN)"
else
    echo -e "$ERROR Cannot create Lambda function. Exiting."
    exit 1
fi

# AWS CLI cannot return API Gateway ARN; construct it
API_ARN="arn:aws:execute-api"
API_ARN="${API_ARN}:${AWS_REGION}:${AWS_ACCOUNT_ID}"
API_ARN="${API_ARN}:${API_GATEWAY_ID}"
echo -e "$INFO API_ARN: $(FY $API_ARN)"


# API method for API_RESOURCE_NAME
echo -e "$INFO API method for Resource $(FC $API_RESOURCE_NAME)"

API_METHOD=$(aws apigateway get-method \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --query httpMethod \
    --output text)


# Delete API method if already exists
if [[ "$API_METHOD" == "$API_HTTP_METHOD" ]]; then
    echo -e "$INFO Deleting previous HTTP method"
    aws apigateway delete-method \
        --rest-api-id $API_GATEWAY_ID \
        --resource-id $API_RESOURCE_ID \
        --http-method $API_HTTP_METHOD \
        --output table 
fi
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Deleted previous  $(FC $API_METHOD) method."
else
    echo -e "$ERROR Failed deleting the method. Exiting."
    exit 1
fi

# Creating API method under specified resource
echo -e "$INFO Creating ${API_HTTP_METHOD} under ${API_RESOURCE_NAME} resource"
aws apigateway put-method \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --authorization-type $API_AUTHORIZATION_TYPE \
    --authorizer-id $API_AUTHORIZER_ID \
    --output table
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Method $(FC $API_HTTP_METHOD) created."
else
    echo -e "$ERROR Cannot create $(FC $API_HTTP_METHOD). Exiting."
    exit 1
fi

echo -e "$INFO API put-integration."
aws apigateway put-integration \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --type AWS \
    --integration-http-method $API_HTTP_METHOD \
    --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --output table
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Successfully created API integration."
else
    echo -e "$ERROR Cannot create API integration. Exiting."
    exit 1
fi

echo -e "$INFO API put-method-response."
aws apigateway put-method-response \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --output table
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Successfully created API method response."
else
    echo -e "$ERROR Cannot create API method response. Exiting."
    exit 1
fi

echo -e "$INFO API put-integration-response." 
aws apigateway put-integration-response \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --status-code 200 \
    --selection-pattern "-" \
    --output table
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Successfully created API integration response."
else
    echo -e "$ERROR Cannot create API integration response. Exiting."
    exit 1
fi

# Adding permission for internal calls
echo -e "$INFO API add-permission for internal calls." 
aws lambda add-permission \
    --function-name $LAMBDA_ARN \
    --source-arn "${API_ARN}/*/${API_HTTP_METHOD}/${API_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-1 \
    --action lambda:InvokeFunction 
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Successfully added permission for internal calls."
else
    echo -e "$ERROR Cannot add permission for internal calls. Exiting."
    exit 1
fi

# Adding permission for external calls
echo -e "$INFO API add-permission for external calls." 
aws lambda add-permission \
    --function-name $LAMBDA_ARN \
    --source-arn "${API_ARN}/${API_STAGE}/${API_HTTP_METHOD}/${API_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-2 \
    --action lambda:InvokeFunction 
exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Successfully added permission for external calls."
else
    echo -e "$ERROR Cannot add permission for external calls. Exiting."
    exit 1
fi


echo -e "$INFO Finished creating $(FC $API_HTTP_METHOD) under" \
    "$(FC $API_RESOURCE_NAME) resource" 



# testing
echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_RESOURCE_NAME}) call."
CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
    -H  "Content-Type: application/json" \
    -X ${API_HTTP_METHOD} \
    -d '{"request_id": 1111}' \
    https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME})
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"

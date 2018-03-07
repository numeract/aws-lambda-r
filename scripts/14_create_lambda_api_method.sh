#!/bin/bash


echo -e "$INFO Uploading deployment package on S3"
aws s3 cp ~/${LAMBDA_ZIP} s3://${S3_BUCKET}/lambda/

PRE_EX_LAMBDA=$(aws lambda get-function-configuration \
    --function-name ${LAMBDA_FUNCTION_NAME} \
    --query FunctionName)      
                    
# Delete lambda function if already exists
 
if [[ "${PRE_EX_LAMBDA}" ==  "\"${LAMBDA_FUNCTION_NAME}\"" ]]; then
    echo -e "$INFO Deleting pre-existent lambda function"
    aws lambda delete-function \
        --function-name ${LAMBDA_FUNCTION_NAME} \
        --output table
fi
    


# Create lambda function
echo -e "$INFO Creating lambda function."
aws lambda create-function \
    --region ${AWS_REGION} \
    --function-name ${LAMBDA_FUNCTION_NAME} \
    --code S3Bucket=${S3_BUCKET},S3Key=lambda/${LAMBDA_ZIP} \
    --role ${IAM_LAMBDA_FUNCTION_ROLE} \
    --handler ${LAMBDA_PYTHON_HANDLER}.${LAMBDA_HANDLER_FUNCTION} \
    --runtime ${LAMBDA_RUNTIME} \
    --environment Variables="{R_HOME=/var/task/bin,R_LIBS=/lib/}" \
    --timeout ${LAMBDA_TIMEOUT} \
    --memory-size ${LAMBDA_MEMORY_SIZE} \
    --output table

# Extracting the lambda function ARN
LAMBDA_ARN="$(aws lambda list-functions \
    --query "Functions[?FunctionName==\`${LAMBDA_FUNCTION_NAME}\`].FunctionArn" \
    --output text \
    --region ${AWS_REGION})"
echo -e "$INFO LAMBDA_ARN: $(FY $LAMBDA_ARN)"

API_ARN=$(echo ${LAMBDA_ARN} | \
    sed -e 's/lambda/execute-api/' \
    -e "s/function:${LAMBDA_FUNCTION_NAME}/${API_ID}/")
echo -e "$INFO API_ARN: $(FY $API_ARN)"


# API method for API_RESOURCE_NAME
echo
echo -e "$INFO API method for Resource $(FC $API_RESOURCE_NAME)"

API_METHOD=$(aws apigateway get-method \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --query httpMethod)
                
# Delete API method if already exists
if [[ "${API_METHOD}" ==  "\"${API_HTTP_METHOD}\"" ]]; then
    echo -e "$INFO  Deleting pre-existent HTTP method"
    aws apigateway delete-method \
        --rest-api-id ${API_ID} \
        --resource-id ${API_RESOURCE_ID} \
        --http-method ${API_HTTP_METHOD} \
        --output table 
fi



# Creating API method under specified resource
echo -e "$INFO Creating ${API_HTTP_METHOD} under ${API_RESOURCE_NAME} resource"
aws apigateway put-method \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --authorization-type ${API_AUTHORIZATION_TYPE} \
    --authorizer-id ${API_AUTHORIZER_ID} \
    --output table
    
echo -e "$INFO API put-integration."
aws apigateway put-integration \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --type AWS \
    --integration-http-method ${API_HTTP_METHOD} \
    --uri arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations \
    --output table

echo -e "$INFO API put-method-response."   
aws apigateway put-method-response \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --output table
    
echo -e "$INFO API put-integration-response." 
aws apigateway put-integration-response \
    --rest-api-id ${API_ID} \
    --resource-id ${API_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --status-code 200 \
    --selection-pattern "-" \
    --output table


# Adding permission for internal calls
echo -e "$INFO API add-permission for internal calls." 
aws lambda add-permission \
    --function-name ${LAMBDA_ARN} \
    --source-arn "${API_ARN}/*/${API_HTTP_METHOD}/${API_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-1 \
    --action lambda:InvokeFunction 


# Adding permission for external calls
echo -e "$INFO API add-permission for external calls." 
aws lambda add-permission \
    --function-name ${LAMBDA_ARN} \
    --source-arn "${API_ARN}/${API_STAGE}/${API_HTTP_METHOD}/${API_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-2 \
    --action lambda:InvokeFunction 

echo -e "$INFO Finished creating $(FC $API_HTTP_METHOD) under" \
    "$(FC $API_RESOURCE_NAME) resource" 


# API method for API_ALIAS_RESOURCE_NAME
echo
echo -e "$INFO API method for Resource $(FC $API_ALIAS_RESOURCE_NAME)"

API_ALIAS_METHOD=$(aws apigateway get-method --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --query httpMethod)
                
# Delete API method if already exists
if [[ "${API_ALIAS_METHOD}" ==  "\"${API_HTTP_METHOD}\"" ]]; then
   echo -e "$INFO  Deleting pre-existent HTTP method"
   aws apigateway delete-method \
        --rest-api-id ${API_ID} \
        --resource-id ${API_ALIAS_RESOURCE_ID} \
        --http-method ${API_HTTP_METHOD} \
        --output table 
fi

# Creating API method under specified resource
echo -e "$INFO Creating ${API_HTTP_METHOD} under ${API_ALIAS_RESOURCE_NAME} resource"
aws apigateway put-method \
    --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --authorization-type ${API_AUTHORIZATION_TYPE} \
    --authorizer-id ${API_AUTHORIZER_ID} \
    --output table

echo -e "$INFO API put-integration."
aws apigateway put-integration \
    --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --type AWS \
    --integration-http-method ${API_HTTP_METHOD} \
    --uri arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations \
    --output table

echo -e "$INFO API put-method-response."   
aws apigateway put-method-response \
    --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --output table

echo -e "$INFO API put-integration-response."
aws apigateway put-integration-response \
    --rest-api-id ${API_ID} \
    --resource-id ${API_ALIAS_RESOURCE_ID} \
    --http-method ${API_HTTP_METHOD} \
    --status-code 200 \
    --selection-pattern "-" \
    --output table


# Adding permission for internal calls
echo -e "$INFO API add-permission for internal calls." 
aws lambda add-permission \
    --function-name ${LAMBDA_ARN} \
    --source-arn "${API_ARN}/*/${API_HTTP_METHOD}/${API_ALIAS_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-3 \
    --action lambda:InvokeFunction 


# Adding permission for external calls
echo -e "$INFO API add-permission for external calls." 
aws lambda add-permission \
    --function-name ${LAMBDA_ARN} \
    --source-arn "${API_ARN}/${API_STAGE}/${API_HTTP_METHOD}/${API_ALIAS_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-4 \
    --action lambda:InvokeFunction 

echo -e "$INFO Finished creating $(FC $API_HTTP_METHOD) under" \
    "$(FC $API_ALIAS_RESOURCE_NAME) resource" 
 

echo -e "$INFO API create-deployment." 
aws apigateway create-deployment \
    --rest-api-id ${API_ID} \
    --stage-name ${API_STAGE} \
    --description ${LAMBDA_FUNCTION_NAME} \
    --output table

echo -e "$INFO API stage updating description."    
aws apigateway update-stage \
    --rest-api-id ${API_ID} \
    --stage-name ${API_STAGE} \
    --patch-operations op=replace,path=/description,value=${LAMBDA_FUNCTION_NAME} \
    --output table



echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_RESOURCE_NAME}) call."
CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
    -H  "Content-Type: application/json" \
    -X ${API_HTTP_METHOD} \
    -d '{"request_id": 1111}' \
    https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME})
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"

echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_ALIAS_RESOURCE_NAME}) call."
CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
    -H  "Content-Type: application/json" \
    -X ${API_HTTP_METHOD} \
    -d '{"request_id": 1111}' \
    https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME})
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"

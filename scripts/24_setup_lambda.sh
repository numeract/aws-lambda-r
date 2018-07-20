#!/bin/bash

# check if Lambda exists given the config variables, create it if not


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


echo
echo -e "$INFO Setting up AWS Lambda and API Gateway infrastructure ..."


# some default names, if missing
if [[ $IAM_LAMBDA_ROLE_NAME == "$MISSING" ]]; then
    IAM_LAMBDA_ROLE_NAME="${PRJ_NAME}-lambda-role"
fi
if [[ $LAMBDA_AUTHORIZER_NAME == "$MISSING" ]]; then
    LAMBDA_AUTHORIZER_NAME="${PRJ_NAME}-lambda-authorizer"
fi
if [[ $API_GATEWAY_NAME == "$MISSING" ]]; then
    API_GATEWAY_NAME="${PRJ_NAME}-api"
fi
if [[ $API_RESOURCE_NAME == "$MISSING" ]]; then
    API_RESOURCE_NAME="resource-v1"
fi
if [[ ! $API_ALIAS_RESOURCE_USE == "false" ]]; then
    if [[ $API_ALIAS_RESOURCE_NAME == "$MISSING" ]]; then
        API_ALIAS_RESOURCE_NAME="resource"
    fi
else
    # want to be sure that they are left undefined, escape \ for echo
    API_ALIAS_RESOURCE_NAME="\$MISSING"
    API_ALIAS_RESOURCE_ID="\$MISSING"
fi
if [[ $API_AUTHORIZER_NAME == "$MISSING" ]]; then
    API_AUTHORIZER_NAME="${PRJ_NAME}-api-authorizer"
fi


# Do not create a new Role if already present
IAM_LAMBDA_ROLE_NAME_OLD="$(aws $AWS_PRFL iam list-roles \
    --region $AWS_REGION \
    --query Roles[?RoleName==\`${IAM_LAMBDA_ROLE_NAME}\`].RoleName \
    --output text)"
if [[ "$IAM_LAMBDA_ROLE_NAME_OLD" == "$IAM_LAMBDA_ROLE_NAME" ]]; then
    echo -e "$INFO Reusing old Lambda Role $(FC $IAM_LAMBDA_ROLE_NAME_OLD)"
else
    # Create a role; Lambda will be allowed to assume this role
    echo -e "$INFO Creating Lambda Role ..."
    aws $AWS_PRFL iam create-role \
        --region $AWS_REGION \
        --role-name $IAM_LAMBDA_ROLE_NAME \
        --assume-role-policy-document file://${IAM_LAMBDA_ROLE_TRUST_FILE} \
        --description "${PRJ_NAME} Role for Lambda Authorizer and Functions" \
        --output table
    # The AWS name of policy assigned to Lambda execution role
    IAM_LAMBDA_ROLE_POLICY_NAME="${PRJ_NAME}-lambda-role-policy"
    # Attach inline policy to role (what Lambda is allowed to do)
    aws $AWS_PRFL iam put-role-policy \
        --region $AWS_REGION \
        --role-name $IAM_LAMBDA_ROLE_NAME  \
        --policy-name $IAM_LAMBDA_ROLE_POLICY_NAME \
        --policy-document file://${IAM_LAMBDA_ROLE_POLICY_FILE}
    # need to wait for ARN to become available
    sleep 10
fi

# Get the ARN of the IAM Lambda Role, to pass it to the Lambda Authorizer Function
IAM_LAMBDA_ROLE_ARN="$(aws $AWS_PRFL iam get-role \
    --region $AWS_REGION \
    --role-name $IAM_LAMBDA_ROLE_NAME \
    --query Role.Arn \
    --output text)"
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO IAM Lambda Role ARN: $(FC $IAM_LAMBDA_ROLE_ARN)"
else
    echo -e "$ERROR Failed to obtain ARN of IAM Lambda Role" \
        "$(FC $IAM_LAMBDA_ROLE_NAME). Exiting."
    exit 1
fi


# Do not create a new Lambda Authorizer Function if already present
LAMBDA_AUTHORIZER_NAME_OLD="$(aws $AWS_PRFL lambda list-functions \
    --region $AWS_REGION \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionName" \
    --output text)"
if [[ "$LAMBDA_AUTHORIZER_NAME_OLD" == "$LAMBDA_AUTHORIZER_NAME" ]]; then
    echo -e "$INFO Reusing old Lambda Authorizer Function" \
        "$(FC $LAMBDA_AUTHORIZER_NAME_OLD)"
else
    # Create a Lambda Authorizer Function
    echo -e "$INFO Creating Lambda Authorizer Function ..."
    # zip the js file containing the Authorizer function
    zip -joq9 ${LAMBDA_AUTHORIZER_FILE}.zip ${LAMBDA_AUTHORIZER_FILE}
    JS_MODULE_NAME="$(basename $LAMBDA_AUTHORIZER_FILE .js)"
    aws $AWS_PRFL lambda create-function \
        --region $AWS_REGION \
        --function-name $LAMBDA_AUTHORIZER_NAME \
        --zip-file fileb://${LAMBDA_AUTHORIZER_FILE}.zip \
        --role $IAM_LAMBDA_ROLE_ARN \
        --handler ${JS_MODULE_NAME}.handler \
        --runtime nodejs6.10 \
        --output table
fi

# Get the ARN of the Lambda Authorizer Function; use authorize API Gateway
LAMBDA_AUTHORIZER_ARN="$(aws $AWS_PRFL lambda get-function-configuration \
    --region $AWS_REGION \
    --function-name $LAMBDA_AUTHORIZER_NAME \
    --query FunctionArn \
    --output text)"
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO Lambda Authorizer Function ARN: $(FC $LAMBDA_AUTHORIZER_ARN)"
else
    echo -e "$ERROR Failed to obtain ARN of Lambda Authorizer Function" \
        "$(FC $LAMBDA_AUTHORIZER_NAME). Exiting."
    exit 1
fi


# Do not create a new API if one with the same name already present
API_GATEWAY_NAME_OLD="$(aws $AWS_PRFL apigateway get-rest-apis \
    --region $AWS_REGION \
    --query "items[?name==\`${API_GATEWAY_NAME}\`].name" \
    --output text)"
if [[ "$API_GATEWAY_NAME_OLD" == "$API_GATEWAY_NAME" ]]; then
    echo -e "$INFO Reusing old API Gateway $(FC $API_GATEWAY_NAME_OLD)"
else
    # Creating API
    echo -e "$INFO Creating API Gateway ..."
    aws $AWS_PRFL apigateway create-rest-api \
        --region $AWS_REGION \
        --name $API_GATEWAY_NAME \
        --output table
fi

# Getting API ID
API_GATEWAY_ID="$(aws $AWS_PRFL apigateway get-rest-apis \
    --region $AWS_REGION \
    --query "items[?name==\`${API_GATEWAY_NAME}\`].id" \
    --output text)"
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO API Gateway ID: $(FC $API_GATEWAY_ID)"
else
    echo -e "$ERROR Failed to obtain ID of API Gateway" \
        "$(FC $API_GATEWAY_NAME). Exiting."
    exit 1
fi


# Get API root resource id, use to construct API Gateway resources
ROOT_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --query "items[?path==\`/\`].id" \
    --output text)"
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO API Gateway Root Resource ID: $(FC $ROOT_RESOURCE_ID)"
else
    echo -e "$ERROR Failed to obtain API Gateway Root Resource ID for" \
        "API Gateway $(FC $API_GATEWAY_NAME). Exiting."
    exit 1
fi


# Do not recreate the Resource if already present
API_RESOURCE_NAME_OLD="$(aws $AWS_PRFL apigateway get-resources \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --query "items[?path==\`/${API_RESOURCE_NAME}\`].pathPart" \
    --output text)"
if [[ "$API_RESOURCE_NAME_OLD" == "$API_RESOURCE_NAME" ]]; then
    echo -e "$INFO Reusing old API Gateway Resource" \
        "$(FC /$API_RESOURCE_NAME_OLD)"
else
    # Creating API Resource
    echo -e "$INFO Creating API Gateway Resource ..."
    aws $AWS_PRFL apigateway create-resource \
        --region $AWS_REGION \
        --rest-api-id $API_GATEWAY_ID \
        --parent-id $ROOT_RESOURCE_ID \
        --path-part $API_RESOURCE_NAME \
        --output table
    # need to wait for the API Resource to become available
    sleep 5
fi

# Get ID of API Resource
API_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --query "items[?path==\`/${API_RESOURCE_NAME}\`].id" \
    --output text)"
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO API Gateway Resource ID: $(FC $API_RESOURCE_ID)"
else
    echo -e "$ERROR Failed to obtain API Gateway Resource ID for" \
        "API Gateway Resource $(FC /$API_RESOURCE_NAME). Exiting."
    exit 1
fi


# Do not recreate the Alias Resource if already present
if [[ ! $API_ALIAS_RESOURCE_USE == "false" ]]; then
    API_ALIAS_RESOURCE_NAME_OLD="$(aws $AWS_PRFL apigateway get-resources \
        --region $AWS_REGION \
        --rest-api-id $API_GATEWAY_ID \
        --query "items[?path==\`/${API_ALIAS_RESOURCE_NAME}\`].pathPart" \
        --output text)"
    if [[ "$API_ALIAS_RESOURCE_NAME_OLD" == "$API_ALIAS_RESOURCE_NAME" ]]; then
        echo -e "$INFO Reusing old API Gateway Alias Resource" \
            "$(FC /$API_ALIAS_RESOURCE_NAME_OLD)"
    else
        # Creating API Alias Resource
        echo -e "$INFO Creating API Gateway Alias Resource ..."
        aws $AWS_PRFL apigateway create-resource \
            --region $AWS_REGION \
            --rest-api-id $API_GATEWAY_ID \
            --parent-id $ROOT_RESOURCE_ID \
            --path-part $API_ALIAS_RESOURCE_NAME \
            --output table
        # need to wait for the API Alias Resource to become available
        sleep 5
    fi

    # Get ID of API Alias Resource
    API_ALIAS_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
        --region $AWS_REGION \
        --rest-api-id $API_GATEWAY_ID \
        --query "items[?path==\`/${API_ALIAS_RESOURCE_NAME}\`].id" \
        --output text)"
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "$INFO API Gateway Alias Resource ID:" \
            "$(FC $API_ALIAS_RESOURCE_ID)"
    else
        echo -e "$ERROR Failed to obtain API Gateway Alias Resource ID for" \
            "API Gateway Alias Resource $(FC /$API_ALIAS_RESOURCE_NAME). Exiting."
        exit 1
    fi
fi


# Do not create an API Gateway Authorizer if already present
API_AUTHORIZER_NAME_OLD="$(aws $AWS_PRFL apigateway get-authorizers \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --query "items[?name==\`${API_AUTHORIZER_NAME}\`].name" \
    --output text)"
if [[ "$API_AUTHORIZER_NAME_OLD" == "$API_AUTHORIZER_NAME" ]]; then
    echo -e "$INFO Reusing old API Gateway Authorizer" \
        "$(FC $API_AUTHORIZER_NAME_OLD)"
else
    # Creating API Authorizer
    echo -e "$INFO Creating API Gateway Authorizer ..."
    AUTHORIZER_URI="arn:aws:apigateway:"
    AUTHORIZER_URI="${AUTHORIZER_URI}${AWS_REGION}"
    AUTHORIZER_URI="${AUTHORIZER_URI}:lambda:path/2015-03-31/functions/"
    AUTHORIZER_URI="${AUTHORIZER_URI}${LAMBDA_AUTHORIZER_ARN}"
    AUTHORIZER_URI="${AUTHORIZER_URI}/invocations"
    echo -e "$INFO API Authorizer URI: $(FC $AUTHORIZER_URI)"
    aws $AWS_PRFL apigateway create-authorizer \
        --rest-api-id $API_GATEWAY_ID \
        --name $API_AUTHORIZER_NAME \
        --type TOKEN \
        --authorizer-uri "$AUTHORIZER_URI" \
        --identity-source 'method.request.header.Auth' \
        --authorizer-result-ttl-in-seconds 300 \
        --output table
    # need to wait for the API Authorizer to become available
    sleep 5
fi

# Get ID of API Authorizer
API_AUTHORIZER_ID="$(aws $AWS_PRFL apigateway get-authorizers \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --query "items[?name==\`${API_AUTHORIZER_NAME}\`].id" \
    --output text)"  
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO API Gateway Authorizer ID: $(FC $API_AUTHORIZER_ID)"
else
    echo -e "$ERROR Failed to obtain API Gateway Authorizer ID for" \
        "API Gateway Authorizer $(FC /$API_AUTHORIZER_NAME). Exiting."
    exit 1
fi


# Add permissions for invocation of the Lambda Authorizer Function, if missing
STATEMENT_ID="${PRJ_NAME}-lambda-1"
LAMBDA_AUTHORIZER_POLICY_OLD=$(aws $AWS_PRFL lambda get-policy \
    --region $AWS_REGION \
    --function-name $LAMBDA_AUTHORIZER_ARN \
    --query "Policy" \
    --output text)
if $(echo "$LAMBDA_AUTHORIZER_POLICY_OLD" | grep -q "$STATEMENT_ID"); then
    echo -e "$INFO Reusing old Lambda Authorizer Policy" \
        "$(FC \"Sid\":\"${STATEMENT_ID}\")"
else
    echo -e "$INFO Adding permission to invoke Lambda Authorizer ..."
    # AWS CLI cannot return API Gateway Authorizer ARN; construct it
    API_AUTHORIZER_ARN="arn:aws:execute-api"
    API_AUTHORIZER_ARN="${API_AUTHORIZER_ARN}:${AWS_REGION}:${AWS_ACCOUNT_ID}"
    API_AUTHORIZER_ARN="${API_AUTHORIZER_ARN}:${API_GATEWAY_ID}"
    API_AUTHORIZER_ARN="${API_AUTHORIZER_ARN}/authorizers/${API_AUTHORIZER_ID}"
    echo -e "$INFO API Gateway Authorizer ARN: $(FC $API_AUTHORIZER_ARN)"
    aws $AWS_PRFL lambda add-permission \
        --region $AWS_REGION \
        --function-name "$LAMBDA_AUTHORIZER_ARN" \
        --statement-id "$STATEMENT_ID" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "$API_AUTHORIZER_ARN" \
        --output table
fi


# append to setup_auto.sh
echo -e "$INFO Appending to $(FY $(basename $SETUP_AUTO_PATH)):"
echo -en \
    "\n # Added on: $(date -u '+%Y-%m-%d %H:%M:%S %Z')\n" \
    "IAM_LAMBDA_ROLE_NAME=\"${IAM_LAMBDA_ROLE_NAME}\"\n" \
    "IAM_LAMBDA_ROLE_ARN=\"${IAM_LAMBDA_ROLE_ARN}\"\n" \
    "LAMBDA_AUTHORIZER_NAME=\"${LAMBDA_AUTHORIZER_NAME}\"\n" \
    "LAMBDA_AUTHORIZER_ARN=\"${LAMBDA_AUTHORIZER_ARN}\"\n" \
    "API_GATEWAY_NAME=\"${API_GATEWAY_NAME}\"\n" \
    "API_GATEWAY_ID=\"${API_GATEWAY_ID}\"\n" \
    "API_RESOURCE_NAME=\"${API_RESOURCE_NAME}\"\n" \
    "API_RESOURCE_ID=\"${API_RESOURCE_ID}\"\n" \
    "API_ALIAS_RESOURCE_NAME=\"${API_ALIAS_RESOURCE_NAME}\"\n" \
    "API_ALIAS_RESOURCE_ID=\"${API_ALIAS_RESOURCE_ID}\"\n" \
    "API_AUTHORIZER_NAME=\"${API_AUTHORIZER_NAME}\"\n" \
    "API_AUTHORIZER_ID=\"${API_AUTHORIZER_ID}\"\n" \
    | sed -e 's/^[ ]*//' | tee -a $SETUP_AUTO_PATH

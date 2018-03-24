#!/bin/bash

# delete Lambda and API Gateway setup created by `24_setup_lambda.sh`
# work in progress !!

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


echo 
echo -e "$INFO Removing previous AWS Lambda and API Gateway setup ..."

# Delete old Lambda Authorizer Function
LAMBDA_AUTHORIZER_NAME_OLD="$(aws $AWS_PRFL lambda list-functions \
    --region $AWS_REGION \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionName" \
    --output text)"
if [[ "$LAMBDA_AUTHORIZER_NAME_OLD" == "$LAMBDA_AUTHORIZER_NAME" ]]; then
    echo -e "$INFO Deleting old Lambda Authorizer Function" \
        "$(FC $LAMBDA_AUTHORIZER_NAME_OLD) ..."
    aws $AWS_PRFL lambda delete-function \
        --region $AWS_REGION \
        --function-name $LAMBDA_AUTHORIZER_NAME
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo -e "$ERROR Cannot delete Lambda Authorizer Function" \
            "$(FC $LAMBDA_AUTHORIZER_NAME). Exiting."
        exit 1
    fi
else
    echo -e "$INFO Lambda Authorizer Function $(FC $LAMBDA_AUTHORIZER_NAME) not found."
fi

# Delete old Role
IAM_LAMBDA_ROLE_NAME_OLD="$(aws $AWS_PRFL iam list-roles \
    --region $AWS_REGION \
    --query Roles[?RoleName==\`${IAM_LAMBDA_ROLE_NAME}\`].RoleName \
    --output text)"
if [[ "$IAM_LAMBDA_ROLE_NAME_OLD" == "$IAM_LAMBDA_ROLE_NAME" ]]; then

    echo -e "$INFO Deleting old Lambda Role Policy" \
        "$(FC $IAM_LAMBDA_ROLE_POLICY_NAME) ..."
    aws $AWS_PRFL iam delete-role-policy \
        --region $AWS_REGION \
        --role-name $IAM_LAMBDA_ROLE_NAME  \
        --policy-name $IAM_LAMBDA_ROLE_POLICY_NAME
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo -e "$WARN Cannot delete old Lambda Role Policy" \
            "$(FC $IAM_LAMBDA_ROLE_POLICY_NAME). Attempting to delete Lambda Role ..."
    fi

    echo -e "$INFO Deleting old Lambda Role $(FC $IAM_LAMBDA_ROLE_NAME_OLD) ..."
    aws $AWS_PRFL iam delete-role \
        --role-name $IAM_LAMBDA_ROLE_NAME
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo -e "$ERROR Cannot delete Lambda Role $(FC $IAM_LAMBDA_ROLE_NAME)." \
            "Exiting."
        exit 1
    fi
else
    echo -e "$INFO Lambda Role $(FC $IAM_LAMBDA_ROLE_NAME) not found."
fi

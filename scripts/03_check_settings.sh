#!/bin/bash

# check & display setting and git, ask for confirmation to proceed


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# are we in the right project?
if [[ ! "$GIT_NAME" == "$PRJ_NAME" ]]; then
    echo -e "$ERROR Expected to be in project $(FC $PRJ_NAME)," \
            "instead got $(FC $GIT_NAME). Exiting."
    exit 1
fi


# git status of this repo
echo -e "$INFO Checking repo $(FY $PRJ_NAME) ..."
git status

# git status as an array of lines
mapfile -t GIT_STATUS <<< $(git status)

# check if on the right branch
if $(echo ${GIT_STATUS[0]} | grep -q "On branch $PRJ_BRANCH"); then
    echo -e "$INFO On branch $(FC '('$PRJ_BRANCH')')"
else 
    echo -e "$ERROR Not on branch $(FC '('$PRJ_BRANCH')'). Exiting."
    exit 1
fi

# check if this branch is clean
if $(echo ${GIT_STATUS[*]} | grep -q "nothing to commit, working tree clean"); then
    echo -e "$INFO Branch $(FC '('$PRJ_BRANCH')') is clean."
else
    if [[ "$DEBUG" == "skip_commit" ]]; then
        echo -e "$WARN Branch $(FC '('$PRJ_BRANCH')') is NOT clean!" \
            "Ignoring check due to DEBUG flag."
    else
        echo -e "$ERROR Branch $(FC '('$PRJ_BRANCH')') is NOT clean!" \
            "Please commit changes. Exiting."
        exit 1
    fi
fi

# check if up-to-date with remote
if $(echo ${GIT_STATUS[*]} | grep -q "Your branch is up-to-date"); then
    echo -e "$INFO Branch $(FC '('$PRJ_BRANCH')') is up-to-date."
else
    echo -e "$WARN Not all commits on branch $(FC '('$PRJ_BRANCH')')" \
        "pushed to remote or not tracking changes."
    # exit 1
fi


# summary of the set variables and secrets
echo -e '\n------------------------- EC2 INSTANCE ---------------------------\n'

if [[ $EC2_CUSTOM_AMI_ID == "$MISSING" ]]; then
    echo -e "No Custom AMI present, using Default AMI: $(FC $EC2_AMI_ID)"
else
    echo -e "Found Custom AMI (skip update and install): $(FC $EC2_AMI_ID)"
fi
echo -e "Instance Type: $(FC $EC2_INSTANCE_TYPE)"

if [[ ! $EC2_SUBNET_ID == "subnet-$MISSING" ]]; then
    echo -e "Subnet ID: $(FC $EC2_SUBNET_ID)"
else
    echo -e "$ERROR Subnet ID: $(FC $EC2_SUBNET_ID). Exiting."
    exit 1
fi

if [[ ! $EC2_SECURITY_GROUP_IDS == "sg-$MISSING" ]]; then
    echo -e "Security Group ID: $(FC $EC2_SECURITY_GROUP_IDS)"
else
    echo -e "$ERROR Security Group ID: $(FC $EC2_SECURITY_GROUP_IDS). Exiting."
    exit 1
fi

echo -e "EC2 user name: $(FC $EC2_USERNAME)"


echo -e '\n------------------------- SSH KEY --------------------------------\n'

if [[ ! $EC2_KEY_NAME == "$MISSING" ]]; then
    echo -e "Your SSH key name is $(FC $EC2_KEY_NAME)" \
        "and it is located in $(FY $EC2_KEY_FILE)"
else
    echo -e "$ERROR EC2_KEY_NAME is $MISSING. Exiting."
    exit 1
fi


echo -e '\n------------------------- AWS CREDENTIALS ------------------------\n'

if [[ ! $IAM_ACCESS_KEY_ID == "$MISSING" ]]; then
    echo -e "Your AWS access key is:" \
        "$(FC "********$(printf $IAM_ACCESS_KEY_ID | tail -c 4)")"
else
    echo -e "$ERROR Your AWS access key is: $MISSING. Exiting."
    exit 1
fi

if [[ ! $IAM_SECRET_ACCESS_KEY == "$MISSING" ]]; then
    echo -e "Your AWS secret access key is:" \
        "$(FC "********$(printf $IAM_SECRET_ACCESS_KEY | tail -c 4)")"
else
    echo -e "$ERROR Your AWS secret access key is: $MISSING. Exiting."
    exit 1
fi

echo -e "AWS Region: $(FC $AWS_REGION)"


echo -e '\n------------------------- S3 BUCKET ------------------------------\n'

if [[ ! $S3_BUCKET == "$MISSING" ]]; then
    echo -e "S3 Bucket for the deployment package: $(FC $S3_BUCKET)"
else
    echo -e "$ERROR S3 Bucket for deployment package: $MISSING. Exiting."
    exit 1
fi


echo -e '\n------------------------- LAMBDA SETTINGS ------------------------\n'

echo -e "Lambda function name: $(FC $LAMBDA_FUNCTION_NAME)"

if [[ ! $IAM_LAMBDA_FUNCTION_ROLE == "$MISSING" ]]; then
    echo -e "IAM Lambda Function Role: $(FY $IAM_LAMBDA_FUNCTION_ROLE)"
else
    echo -e "$ERROR Lambda Function Role: $MISSING. Exiting."
    exit 1
fi


echo -e '\n------------------------- API GATEWAY ----------------------------\n'

# if [[ ! $API_ID  == "$MISSING" ]]; then
#     echo -e "API Gateway ID: $(FC $API_ID)"
# else
#     echo -e "$ERROR API Gateway ID: $MISSING. Exiting."
#     exit 1
# fi

# if [[ ! $API_RESOURCE_ID  == "$MISSING" ]]; then
#     echo -e "API Resource ID: $(FC $API_RESOURCE_ID)"
# else
#     echo -e "$ERROR API Resource ID: $MISSING. Exiting."
#     exit 1
# fi


if [[ ! $API_ALIAS_RESOURCE_ID  == "$MISSING" ]]; then
    echo -e "API Alias Resource ID: $(FC $API_ALIAS_RESOURCE_ID)"
    # checking if the API resources are the same
    if [[ $API_ALIAS_RESOURCE_ID  == $API_RESOURCE_ID ]]; then
        echo -e "$ERROR API Resource and Resource Alias should not" \
            "be the same. Exiting."
        exit 1
    fi
else
    echo -e "$WARN API Alias Resource ID: $MISSING. Ignoring it."
fi


# if [[ ! $API_AUTHORIZER_ID == "$MISSING" ]]; then
#     echo -e "API Authorizer ID: $(FC $API_AUTHORIZER_ID)"
# else
#     echo -e "$ERROR API Authorizer ID: $MISSING. Exiting."
#     exit 1
# fi

# if [[ ! $API_TOKEN == "$MISSING" ]]; then
#     echo -e "API Gateway authorization token: $(FC $API_TOKEN)"
# else
#     echo -e "$ERROR API Gateway authorization token: $MISSING. Exiting."
#     exit 1
# fi


# confirmation
echo
echo -e "$INFO You are on git branch $(FC '('$PRJ_BRANCH')')"\
    "deploying to API stage $(BY $API_STAGE), resource ID $(BY $API_RESOURCE_ID)"

read -p "$(FY 'WARN :') To confirm, type the name of the API stage: "
if [[ ! "$REPLY" == "$API_STAGE" ]]; then
    echo -e "$ERROR API stage entered does not match. Exiting."
    exit 1
fi


# double-check for 'prod' stage. Ask for confirmation to deploy to prod stage
if [[ "$API_STAGE" == "prod" ]]; then
    read -p "$(FY 'WARN :') This is the $(BY 'prod') stage! Re-type the name of the stage to continue: "
    if [[ ! "$REPLY" == "$API_STAGE" ]]; then
        echo -e "$ERROR API stage entered does not match. Exiting."
        exit 1
    fi
fi

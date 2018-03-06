#!/bin/bash

# check & display setting and git, ask for confirmation to proceed


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# are we in the right project?
if [[ ! "$GIT_NAME" == "$PRJ_NAME" ]]; then
    echo -e "$ERROR Expected to be in project $(FC $PRJ_NAME)," \
            "instead got $(FC $GIT_NAME). Aborting."
    exit 1
fi


# git status of this repo
echo -e "$INFO Checking repo $(FY $PRJ_NAME)"
git status

# git status as an array of lines
mapfile -t GIT_STATUS <<< $(git status)

# check if on the right branch
if $(echo ${GIT_STATUS[0]} | grep -q "On branch $PRJ_BRANCH"); then
    echo -e "$INFO On branch $(FC '('$PRJ_BRANCH')')"
else 
    echo -e "$ERROR Not on branch $(FC '('$PRJ_BRANCH')'). Aborting."
    exit 1
fi

# check if this branch is clean
if $(echo ${GIT_STATUS[*]} | grep -q "nothing to commit, working tree clean"); then 
    echo -e "$INFO Branch $(FC '('$PRJ_BRANCH')') is clean."
else 
    echo -e "$ERROR Branch $(FC '('$PRJ_BRANCH')') is NOT clean!" \
        "Please commit changes. Aborting."
    [[ "$DEBUG" == "skip_commit" ]] || exit 1
fi

# check if up-to-date with remote
if $(echo ${GIT_STATUS[*]} | grep -q "Your branch is up-to-date"); then
    echo -e "$INFO Branch $(FC '('$PRJ_BRANCH')') is up-to-date."
else
    echo -e "$WARN Not all commits on branch $(FC '('$PRJ_BRANCH')')" \
        "pushed to GitHub or not tracking."
    # exit 1
fi


# summary of the set variables and secrets
echo -e '\n---------------------- EC2 INSTANCE SETTINGS ---------------------\n'

echo -e "You are going to create an EC2 instance with the following characteristics:"
echo -e "AMI: $(FC $EC2_AMI_ID)"
echo -e "Instance Type: $(FC $EC2_INSTANCE_TYPE)"

if [[ ! $EC2_SECURITY_GROUP_IDS  == "$MISSING" ]]; then
    echo -e "Security group is: $(FC $EC2_SECURITY_GROUP_IDS) "
else
    echo -e "$ERROR Security group is: $MISSING"
    exit 1
fi

if [[ ! $EC2_SUBNET_ID  == "$MISSING" ]]; then
    echo -e "Subnet Id is: $(FC $EC2_SUBNET_ID)"
else
    echo -e "$ERROR Subnet Id is: $MISSING"
    exit 1
fi

#echo -e "Instance profile name : $INSTANCE_PROFILE_NAME"
echo -e "User name: $(FC $EC2_USERNAME)"


echo -e '\n------------------- SSH KEY NAME AND LOCATION --------------------\n'

echo -e "Your key name is: $(FC $EC2_KEY_NAME)" \
    "and it is located in: $(FY $EC2_KEY_FILE)"


echo -e '\n------------------------ AWS CREDENTIALS -------------------------\n'

if [[ ! $IAM_ACCESS_KEY_ID == "$MISSING" ]]; then
    echo -e "Your AWS access key is:$(FC $IAM_ACCESS_KEY_ID)"
else
    echo -e "$ERROR Your AWS access key is: $MISSING"
    exit 1
fi

if [[ ! $IAM_SECRET_ACCESS_KEY == "$MISSING" ]]; then
    echo -e "Your secret access key is: $(FC $IAM_SECRET_ACCESS_KEY)"
else
    echo -e "$ERROR Your secret access key is: $MISSING"
    exit 1
fi

echo -e "Selected region: $(FC $AWS_REGION)"


echo -e '\n------------------------ LAMBDA SETTINGS -------------------------\n'

echo -e "Lambda function name is: $(FC $LAMBDA_FUNCTION_NAME)"

if [[ ! $IAM_LAMBDA_FUNCTION_ROLE  == "$MISSING" ]]; then
    echo -e "IAM Lambda function role is: $(FY $IAM_LAMBDA_FUNCTION_ROLE)"
else
    echo -e "$ERROR Lambda function role is: $MISSING"
    exit 1
fi


echo -e '\n------------------------ S3 BUCKET -------------------------\n'

if [[ ! $S3_BUCKET == "$MISSING" ]]; then
    echo -e "S3 Bucket for deployment package is: $(FC $S3_BUCKET)"
else
    echo -e "$ERROR S3 Bucket for deployment package is: $MISSING"
    exit 1
fi


echo -e '\n------------------------ API SECRETS -------------------------\n'

if [[ ! $API_ID  == "$MISSING" ]]; then
    echo -e "API Gateway Id is: $(FC $API_ID)"
else
    echo -e "$ERROR API Gateway Id is: $MISSING"
    exit 1
fi

if [[ ! $API_RESOURCE_ID  == "$MISSING" ]]; then
    echo -e "API Resource Id is: $(FC $API_RESOURCE_ID)"
else
    echo -e "$ERROR API Resource Id is: $MISSING"
    exit 1
fi


if [[ ! $API_ALIAS_RESOURCE_ID  == "$MISSING" ]]; then
    echo -e "API Alias Resource Id is: $(FC $API_ALIAS_RESOURCE_ID)"
else
    echo -e "$ERROR API Alias Resource Id is: $MISSING"
    exit 1
fi


# checking if the API resources are the same
if [[ ! $API_ALIAS_RESOURCE_NAME  == $API_RESOURCE_NAME ]]; then
    echo -e "API Resource name is: $(FC $API_RESOURCE_NAME)"
    echo -e "API Alias Resource name is: $(FC $API_ALIAS_RESOURCE_NAME)"
else
    echo -e "$ERROR API resource and resource alias should not be the same"
    exit 1
fi


if [[ ! $API_AUTHORIZER_ID  == "$MISSING" ]]; then
    echo -e "API Authorizer ID: $(FC $API_AUTHORIZER_ID)"
else
    echo -e "$ERROR API Authorizer ID: $MISSING"
    exit 1
fi

if [[ ! $API_TOKEN  == "$MISSING" ]]; then
    echo -e "API Gateway authorization token: $(FC $API_TOKEN)"
else
    echo -e "$ERROR API Gateway authorization token: $MISSING"
    exit 1
fi

# confirmation
echo
echo -e "$INFO You are on git branch $(FC '('$PRJ_BRANCH')')"\
    "deploying to API stage $(BY $API_STAGE), resource $(BY $API_RESOURCE_NAME)"

read -p "$(FY 'WARN :') To confirm, type the name of the API stage: "
if [[ ! "$REPLY" == "$API_STAGE" ]]; then
    echo -e "$ERROR API stage entered does not match. Aborting."
    exit 1
fi

# double-check for 'prod' stage. Ask for confirmation to deploy to prod stage
if [[ "$API_STAGE" == "prod" ]]; then
    read -p "$(FY 'WARN :') This is the $(BY 'prod') stage! Re-type the name of the stage to continue: "
    if [[ ! "$REPLY" == "$API_STAGE" ]]; then
        echo -e "$ERROR API stage entered does not match. Aborting."
        exit 1
    fi
fi

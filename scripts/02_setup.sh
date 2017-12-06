#!/bin/bash

# sets local variables for all local scripts and sources secrets
# `source` this script into local scripts


# variables - available to scripts when using source, but not to sub-processes
INFO="\e[32mINFO :\e[39m"                               # Green
WARN="\e[33mWARN :\e[39m"                               # Yellow
ERROR="\e[31mERROR:\e[39m"                              # Red
MISSING="\e[95mMISSING\e[39m"                           # Magenta


# functions
FY () { echo -e "\e[33m$1\e[39m"; }                     # Foreground Yellow
FC () { echo -e "\e[36m$1\e[39m"; }                     # Foreground Cyan
BY () { echo -e "\e[43m\e[30m$1\e[39m\e[49m"; }         # Background Yellow


# expanded path of the parent dir where this file is located
# since we are sourcing, avoid redefining it (maybe current dir has changed)
echo -e "$INFO Checking project directories"
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
PRJ_DIR="$(cd "$SCR_DIR/.."; pwd)"
SET_DIR="$PRJ_DIR/settings"
PYTHON_DIR="$PRJ_DIR/python"
LAMBDA_DIR="$PRJ_DIR/lambda"

# git related
GIT_DIR="$(cd "$(git rev-parse --show-toplevel)"; pwd)"
GIT_NAME="$(basename $GIT_DIR)"


# did we get the project root right?
if [[ ! "$GIT_DIR" == "$PRJ_DIR" ]]; then
    echo -e "$ERROR Expected git root dir $(FY $PRJ_DIR)," \
    "instead got $(FY $GIT_DIR). Aborting."
    exit 1
fi

# do the other dir exist?
if [[ ! -d "$SCR_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $SCR_DIR), does not exist. Aborting."
    exit 1
fi
if [[ ! -d "$SET_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $SET_DIR), does not exist. Aborting."
    exit 1
fi
if [[ ! -d "$PYTHON_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $PYTHON_DIR), does not exist. Aborting."
    exit 1
fi
if [[ ! -d "$LAMBDA_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $LAMBDA_DIR), does not exist. Aborting."
    exit 1
fi


# locate user specific settings / secrets
echo -e "$INFO Looking for user specific secrets file"
if [[ -z $USER_SECRETS_FILE ]]; then
    # $USER_SECRETS_FILE is null, try loading the setup file, if present
    SETUP_USER_PATH="$SET_DIR/setup_user_secrets.sh"
    if [[ -f $SETUP_USER_PATH ]]; then
        source $SETUP_USER_PATH
    else
        echo -e "$ERROR File $(FY $SETUP_USER_PATH) not found and ... "
    fi
fi
if [[ -z $USER_SECRETS_FILE ]]; then
    # $USER_SECRETS_FILE still null --> error
    echo -e "$ERROR Variable $(FC USER_SECRETS_FILE) not defined. Aborting."
    exit 1
fi


# source default settings and secrets
echo -e "$INFO Loading default settings and secrets"

SETTINGS_DEFAULT_PATH="$SET_DIR/settings_default.sh"
SECRETS_DEFAULT_PATH="$SET_DIR/secrets_default.sh"
DEFAULT_SETUP_PATH="$SET_DIR/default_setup.sh"
SECRETS_USER_PATH="$SET_DIR/$USER_SECRETS_FILE"

source $SETTINGS_DEFAULT_PATH
source $DEFAULT_SETUP_PATH
source $SECRETS_DEFAULT_PATH

if [[ -f $SECRETS_USER_PATH ]]; then
    echo -e "$INFO Loading user specific secrets from $(FY $SECRETS_USER_PATH)"
    source $SECRETS_USER_PATH
else
    echo -e "$ERROR User specific secrets file $(FY $SECRETS_USER_PATH)" \
        "not found. Aborting."
    exit 1
fi

if [[ -f $DEFAULT_SETUP_PATH ]]; then
    echo -e "$INFO Loading user specific setup settings from $(FY $DEFAULT_SETUP_PATH)"
    source $DEFAULT_SETUP_PATH
else
    echo -e "$ERROR User specific setup settings file $(FY $DEFAULT_SETUP_PATH)" \
        "not found. Aborting."
    exit 1
fi


# obtain RESOURCE_NAME from RESOURCE_ID
# The resource containing a particular version of the lambda function
if [[ ! $API_RESOURCE_ID  =~ "MISSING" ]]; then
    # The Name of the resource under the API Gateway
    API_RESOURCE_NAME="$(aws $AWS_PRFL apigateway get-resource \
        --rest-api-id ${API_ID} \
        --resource-id ${API_RESOURCE_ID} \
        --query "pathPart" \
        --output text)"
    exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        echo -e "$ERROR Cannot obtain $(FC API_RESOURCE_NAME) for" \
            "$(FC API_RESOURCE_ID)=\"$API_RESOURCE_ID\""
        exit 1
    fi
else
    echo -e "$ERROR Variable $(FC API_RESOURCE_ID) is: $API_RESOURCE_ID"
    exit 1
fi



# arbitrary AWS Lambda function name - if you change this line search and replace all
LAMBDA_FUNCTION_NAME="${PRJ_NAME}-${PRJ_BRANCH}-${API_STAGE}-${API_RESOURCE_NAME}"

# script to run on EC2 for AMI
EC2_SCR_11="$SCR_DIR/11_install_packages.sh"

# EC2 scripts to be pushed to the server

EC2_SET_1="$SETTINGS_DEFAULT_PATH"
EC2_SET_2="$SECRETS_DEFAULT_PATH"
EC2_SET_3="$SECRETS_USER_PATH"
EC2_SET_4="$DEFAULT_SETUP_PATH"
EC2_SCR_12="$SCR_DIR/12_configure_ec2.sh"
EC2_SCR_13="$SCR_DIR/13_create_deployment_package.sh"
EC2_SCR_14="$SCR_DIR/14_create_lambda_api_method.sh"

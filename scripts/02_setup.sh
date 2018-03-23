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
CURRENT_DIR="$(pwd)"
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
PRJ_DIR="$(cd "${SCR_DIR}/.."; pwd)"
SET_DIR="${PRJ_DIR}/settings"
PYTHON_DIR="${PRJ_DIR}/python"
LAMBDA_DIR="${PRJ_DIR}/lambda"
# git related
GIT_DIR="$(cd "$(git rev-parse --show-toplevel)"; pwd)"
GIT_NAME="$(basename $GIT_DIR)"


# did we get the project root right?
if [[ ! "$GIT_DIR" == "$PRJ_DIR" ]]; then
    echo -e "$ERROR Expected git root dir $(FY $PRJ_DIR)," \
    "instead got $(FY $GIT_DIR). Exiting."
    exit 1
fi

# do the other dir exist?
if [[ ! -d "$SCR_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $SCR_DIR), does not exist. Exiting."
    exit 1
fi
if [[ ! -d "$SET_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $SET_DIR), does not exist. Exiting."
    exit 1
fi
if [[ ! -d "$PYTHON_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $PYTHON_DIR), does not exist. Exiting."
    exit 1
fi
if [[ ! -d "$LAMBDA_DIR" ]]; then
    echo -e "$ERROR Dir $(FY $LAMBDA_DIR), does not exist. Exiting."
    exit 1
fi

if [[ $PRJ_DIR != $CURRENT_DIR ]]; then
    echo -e "$ERROR Expected current directory to be $(FY $PRJ_DIR)," \
        "instead got $(FY $CURRENT_DIR)."  \
        "Please change directory before running. Exiting."  
    exit 1
fi

# source default settings and secrets
echo -e "$INFO Loading default settings and secrets"

SETTINGS_DEFAULT_PATH="${SET_DIR}/settings_default.sh"
SECRETS_DEFAULT_PATH="${SET_DIR}/secrets_default.sh"
SETUP_AUTO_PATH="${SET_DIR}/setup_auto.sh"
SETUP_USER_PATH="${SET_DIR}/setup_user.sh"

source $SETTINGS_DEFAULT_PATH
source $SECRETS_DEFAULT_PATH

# locate setup auto file
if [[ -f $SETUP_AUTO_PATH ]]; then
    source $SETUP_AUTO_PATH
else
    echo -e "$WARN File $(FY $SETUP_AUTO_PATH) not found. Skipping."
fi

# locate setup user file
if [[ -f $SETUP_USER_PATH ]]; then
    source $SETUP_USER_PATH
else
    echo -e "$ERROR File $(FY $SETUP_USER_PATH) not found. Exiting."
    exit 1
fi


# basic checks
if [[ $PRJ_NAME == "$MISSING" ]]; then
    echo -e "$ERROR PRJ_NAME is $MISSING. Exiting."
    exit 1
fi

if [[ $PRJ_BRANCH == "$MISSING" ]]; then
    echo -e "$ERROR PRJ_BRANCH is $MISSING. Exiting."
    exit 1
fi


# which AMI ID to use?
if [[ $EC2_CUSTOM_AMI_ID == "$MISSING" ]]; then
    EC2_AMI_ID="$EC2_DEFAULT_AMI_ID"
else
    EC2_AMI_ID="$EC2_CUSTOM_AMI_ID"
fi


# does AWS CLI work? Also get AWS Account ID (used to create ARNs)
AWS_ACCOUNT_ID="$(aws $AWS_PRFL sts get-caller-identity \
    --query "Account" \
    --output text)"
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo -e "$ERROR Failed to obtain AWS Account ID. Is AWS CLI configured?"
    exit 1
fi


# arbitrary AWS Lambda function name
# must match `12_configure_ec2.sh` definition
if [[ $LAMBDA_FUNCTION_NAME == "$MISSING" ]]; then
    LAMBDA_FUNCTION_NAME="${PRJ_NAME}-${PRJ_BRANCH}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_STAGE}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_RESOURCE_NAME}"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME}-${API_HTTP_METHOD}"
    LAMBDA_FUNCTION_NAME="$(echo ${LAMBDA_FUNCTION_NAME} | tr '[A-Z]' '[a-z]')"
    LAMBDA_FUNCTION_NAME="$(echo ${LAMBDA_FUNCTION_NAME} | tr '/' '-')"
fi


# use the right lambda given api method
# must match `02_setup.sh` definition
if [[ $API_HTTP_METHOD == "GET" ]]; then
    LAMBDA_PYTHON_HANDLER="$LAMBDA_PYTHON_HANDLER_GET"
    LAMBDA_HANDLER_FUNCTION="$LAMBDA_HANDLER_FUNCTION_GET"
fi
if [[ $API_HTTP_METHOD == "POST" ]]; then
    LAMBDA_PYTHON_HANDLER="$LAMBDA_PYTHON_HANDLER_POST"
    LAMBDA_HANDLER_FUNCTION="$LAMBDA_HANDLER_FUNCTION_POST"
fi


# settings to be pushed to the EC2 instance
EC2_SET_1="$SETTINGS_DEFAULT_PATH"
EC2_SET_2="$SECRETS_DEFAULT_PATH"
EC2_SET_3="$SETUP_AUTO_PATH"
EC2_SET_4="$SETUP_USER_PATH"

# script to run on EC2 to update / create AMI
EC2_SCR_11="${SCR_DIR}/11_install_packages.sh"

# scripts to run on EC2 to deploy & configure lambda + api gateway
EC2_SCR_12="${SCR_DIR}/12_configure_ec2.sh"
EC2_SCR_13="${SCR_DIR}/13_create_deployment_package.sh"
EC2_SCR_14="${SCR_DIR}/14_create_lambda_api_method.sh"
EC2_SCR_15="${SCR_DIR}/15_create_alias_api_method.sh"

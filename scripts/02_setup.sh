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


# source default settings and secrets
echo -e "$INFO Loading default settings and secrets"

SETTINGS_DEFAULT_PATH="$SET_DIR/settings_default.sh"
SECRETS_DEFAULT_PATH="$SET_DIR/secrets_default.sh"
SETUP_AUTO_PATH="$SET_DIR/setup_auto.sh"
SETUP_USER_PATH="$SET_DIR/setup_user.sh"

source $SETTINGS_DEFAULT_PATH
source $SECRETS_DEFAULT_PATH

# locate setup auto
if [[ -f $SETUP_AUTO_PATH ]]; then
    source $SETUP_AUTO_PATH
else
    echo -e "$WARN File $(FY $SETUP_AUTO_PATH) not found. Skipping."
fi

# locate setup user
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


# arbitrary AWS Lambda function name 
# if you change this line, search and replace all sh files where it is redefined
LAMBDA_FUNCTION_NAME="${PRJ_NAME}-${PRJ_BRANCH}-${API_STAGE}"


#!/bin/bash

# check if S3 bucket exists given the config variables, create it if not


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# if S3 name is missing:
# - try "<account alias>-${PRJ_NAME}"
# - if no account alias, use "<last 4 digits of account ID>-${PRJ_NAME}"
if [[ $S3_BUCKET == "$MISSING" ]]; then
    AWS_ACCOUNT_ALIAS=$(aws $AWS_PRFL iam list-account-aliases \
        --query "AccountAliases[0]" \
        --output text)
    if [[ $AWS_ACCOUNT_ALIAS == "None" ]]; then
        S3_BUCKET=""$(printf $AWS_ACCOUNT_ID | tail -c 4)"-${PRJ_NAME}"
    else
        S3_BUCKET="${AWS_ACCOUNT_ALIAS}-${PRJ_NAME}"
    fi
    S3_BUCKET="$(echo ${S3_BUCKET} | tr '[A-Z]' '[a-z]')"
fi
echo -e "$INFO S3 Bucket to use: $(FC $S3_BUCKET)"


# check existence
if aws $AWS_PRFL s3 ls "s3://${S3_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo -e "$INFO S3 Bucket $(FC $S3_BUCKET) does not exist. Creating it ..."
else
    echo -e "$ERROR S3 Bucket $(FC $S3_BUCKET) already exists. Exiting."
    exit 1
fi


# creating S3 Bucket
if [[ $AWS_REGION == "us-east-1" ]]; then
    aws $AWS_PRFL s3api create-bucket \
        --bucket ${S3_BUCKET} \
        --region ${AWS_REGION} \
        --output table
else    
    aws $AWS_PRFL s3api create-bucket \
        --bucket ${S3_BUCKET} \
        --region ${AWS_REGION} \
        --create-bucket-configuration LocationConstraint=${AWS_REGION} \
        --output table
fi


# test existence
if aws $AWS_PRFL s3 ls "s3://${S3_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo -e "$ERROR S3 Bucket $(FC $S3_BUCKET) still does not exist." \
        "Please create it from AWS Web Console. Exiting."
    exit 1
else
    echo -e "$INFO S3 Bucket $(FC $S3_BUCKET) now exists."
fi


# append to setup_auto.sh
echo -e "$INFO Appending to $(FY $(basename $SETUP_AUTO_PATH)):"
echo -en \
    "\n# Added on: $(date -u '+%Y-%m-%d %H:%M:%S %Z')\n" \
    "S3_BUCKET=\"${S3_BUCKET}\"\n" \
    | sed -e 's/^[ ]*//' | tee -a $SETUP_AUTO_PATH

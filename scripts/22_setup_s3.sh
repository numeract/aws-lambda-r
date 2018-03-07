#!/bin/bash

# check if S3 bucket exists given the config variables, create it if not


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# if no given name, use a name = last 4 letters of access key and prj name
if [[ $S3_BUCKET == "$MISSING" ]]; then
    S3_BUCKET=""$(printf $IAM_ACCESS_KEY_ID | tail -c 4)"-${PRJ_NAME}"
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
        "Please create it from AWS Web Console."
else
    echo -e "$INFO S3 Bucket $(FC $S3_BUCKET) now exists."
fi

#!/bin/bash

# check if S3 bucket exists given the config variables, create it if not

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# check given name
if [[ $S3_BUCKET == "$MISSING" ]]; then
    S3_BUCKET=""$(printf $IAM_ACCESS_KEY_ID | tail -c 4)"-${PRJ_NAME}"
fi

echo -e "S3 Bucket for the deployment package is: $(FC $S3_BUCKET)"

exit 1

# now we have what we believe to be a valid S3 name; does the bucket exist?
aws $AWS_PRFL s3api wait bucket-exists \
    --bucket ${S3_BUCKET}
exit_status=$?
if [[ $exit_status -ne 0 ]]; then
    OVER=1
else
    TEST=$(( TEST+1 ))
    echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds. Please wait..."
    sleep 5
fi


# TODO: check S3 exists given current name, ignore missing


# Creating S3 Bucket
aws $AWS_PRFL s3api create-bucket \
    --bucket ${S3_BUCKET} \
    --region ${AWS_REGION} \
    --create-bucket-configuration LocationConstraint=${AWS_REGION}

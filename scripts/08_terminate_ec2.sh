#!/bin/bash

# Terminate a known Amazon EC2 Instance


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# terminate a known instance
if [[ -z $EC2_INSTANCE_ID ]]; then
    echo -e "$ERROR No EC2 Instance ID found." \
        "Please also check AWS web console."
else
    echo -e "$INFO Attempting to terminate EC2 Instance ID" \
        "$(FC $EC2_INSTANCE_ID) ..."
    aws $AWS_PRFL ec2 terminate-instances \
        --region $AWS_REGION \
        --instance-ids $EC2_INSTANCE_ID \
        --output table
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is being terminated ..."
    else
        echo -e "$ERROR Cannot terminate Instance ID $(FC $EC2_INSTANCE_ID)." \
            "Please terminate it using AWS web console."
    fi
fi

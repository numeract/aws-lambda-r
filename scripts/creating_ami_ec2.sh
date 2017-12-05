#!/bin/bash

# calls all other local scripts 


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"



source "$SCR_DIR/04_create_ec2.sh"
source "$SCR_DIR/05_update_ec2.sh"


# stop instance

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# terminate a known instance
if [[ -z $EC2_INSTANCE_ID ]]; then
    echo -e "$ERROR No Instance ID found. Please stop it using AWS website."
else
    echo -e "$INFO Attempting to stop Instance $(FC $EC2_INSTANCE_ID)"
    aws $AWS_PRFL ec2 stop-instances --instance-ids $EC2_INSTANCE_ID --output table
    exit_status=$?
    if [[ $exit_status -eq 0 ]]; then
        echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is being stopped."
    else
        echo -e "$ERROR Cannot terminate Instance $(FC $EC2_INSTANCE_ID)." \ 
                "Please terminate it using AWS website console."
    fi
fi

                

AMI_ID=$(aws ec2 create-image --instance-id $EC2_INSTANCE_ID --name "Custom AMI" --output text)
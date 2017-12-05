#!/bin/bash

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"

EC2_AMI_ID="ami-acd005d5"

source "$SCR_DIR/04_create_ec2.sh"
source "$SCR_DIR/05_update_ec2.sh"


# stop instance
# Wait until the machine is stopped


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# stop instance
if [[ -z $EC2_INSTANCE_ID ]]; then
    echo -e "$ERROR No Instance ID found. Please stop it using AWS website."
else
    echo -e "$INFO Attempting to stop Instance $(FC $EC2_INSTANCE_ID)"
    aws $AWS_PRFL ec2 stop-instances --instance-ids $EC2_INSTANCE_ID --output table
    exit_status=$?
    if [[ $exit_status -eq 0 ]]; then
        echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is being stopped."
    else
        echo -e "$ERROR Cannot stop Instance $(FC $EC2_INSTANCE_ID)." \ 
                "Please stop it using AWS website console."
    fi
fi


echo -e "$INFO Waiting for the AWS EC2 Instance to stop ..."
OVER=0
TEST=0
while [[ $OVER -eq 0 ]] && [[ $TEST -lt $EC2_MAX_TESTS ]]; do
    EC2_STATE_NAME=$(aws $AWS_PRFL ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --query Reservations[0].Instances[0].State.Name \
        --output text)
    if [[ "$EC2_STATE_NAME" == "stopped" ]]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds. Please wait ..."
        sleep 5
    fi
done
 

EC2_AMI_ID=$(aws ec2 create-image --instance-id $EC2_INSTANCE_ID --name "Custom AMI" --output text)

echo -en "EC2_AMI_ID=${EC2_AMI_ID}"|  tee -a ../settings/default_setup.sh
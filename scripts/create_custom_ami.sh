#!/bin/bash

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"

EC2_AMI_ID="ami-acd005d5"

source "$SCR_DIR/04_create_ec2.sh"
source "$SCR_DIR/10_connect_to_ec2.sh"
source "$SCR_DIR/15_stop_ec2.sh"


EC2_AMI_ID=$(aws ec2 create-image --instance-id $EC2_INSTANCE_ID --name "Custom AMI" --output text)

# Wait until the image is available
echo -e "$INFO Waiting for the AMI to be available ..."
OVER=0
TEST=0
while [[ $OVER -eq 0 ]] && [[ $TEST -lt $EC2_MAX_TESTS ]]; do
    AMI_STATE=$(aws ec2 describe-images --image-ids $EC2_AMI_ID --query Images[0].State --output text)
    if [[ "$AMI_STATE" == "available" ]]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 10 seconds. Please wait ..."
        sleep 10
    fi
done
 

echo -en "\nEC2_AMI_ID=${EC2_AMI_ID}"|  tee -a ../settings/default_setup.sh

source "$SCR_DIR/08_terminate_ec2.sh"
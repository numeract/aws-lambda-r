#!/bin/bash

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# always start from the default Amazon Linux AMI
EC2_AMI_ID="$EC2_DEFAULT_AMI_ID"

# create and update an instance
source "$SCR_DIR/04_create_ec2.sh"
source "$SCR_DIR/05_update_ec2.sh"

# stop instance
if [[ -z $EC2_INSTANCE_ID ]]; then
    echo -e "$ERROR No EC2 Instance ID found." \
        "Please also check AWS web console. Exiting."
        exit 1
else
    echo -e "$INFO Attempting to stop EC2 Instance ID" \
        "$(FC $EC2_INSTANCE_ID) ..."
    aws $AWS_PRFL ec2 stop-instances \
        --region $AWS_REGION \
        --instance-ids $EC2_INSTANCE_ID \
        --output table
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is being stopped ..."
    else
        echo -e "$ERROR Cannot stop Instance ID $(FC $EC2_INSTANCE_ID)." \ 
            "Please terminate it using AWS website console. Exiting."
        exit 1
    fi
fi

# wait until the instance is stopped
echo -e "$INFO Waiting for the AWS EC2 Instance to stop ..."
OVER=0
TEST=0
while [ $OVER -eq 0 ] && [ $TEST -lt $EC2_MAX_TESTS ]; do
    EC2_STATE_NAME=$(aws $AWS_PRFL ec2 describe-instances \
        --region $AWS_REGION \
        --instance-ids $EC2_INSTANCE_ID \
        --query Reservations[0].Instances[0].State.Name \
        --output text)
    if [[ "$EC2_STATE_NAME" == "stopped" ]]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds ..."
        sleep 5
    fi
done

# create a new custom AMI from the stopped instance, do not delete old AMI
echo -e "$INFO Create custom AMI from Instance ID"
EC2_CUSTOM_AMI_NAME="${PRJ_NAME}-ami_$(date -u '+%Y-%m-%d_%H-%M-%S_%Z')"
EC2_CUSTOM_AMI_ID=$(aws $AWS_PRFL ec2 create-image \
    --region $AWS_REGION \
    --instance-id $EC2_INSTANCE_ID \
    --name "$EC2_CUSTOM_AMI_NAME" \
    --output text)

# Wait until AMI is available - this will take longer
EC2_MAX_TESTS=100
echo -e "$INFO Waiting for AMI ID $(FC $EC2_CUSTOM_AMI_ID) to be available ..."
OVER=0
TEST=0
while [ $OVER -eq 0 ] && [ $TEST -lt $EC2_MAX_TESTS ]; do
    AMI_STATE=$(aws $AWS_PRFL ec2 describe-images \
        --region $AWS_REGION \
        --image-ids $EC2_CUSTOM_AMI_ID \
        --query Images[0].State \
        --output text)
    if [[ "$AMI_STATE" == "available" ]]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds ..."
        sleep 5
    fi
done
 
# terminating the stopped instance
    source "$SCR_DIR/08_terminate_ec2.sh"
    
# append to setup_auto.sh
echo -e "$INFO Appending to $(FY $(basename $SETUP_AUTO_PATH)):"
echo -en \
    "\n# Added on: $(date -u '+%Y-%m-%d %H:%M:%S %Z')\n" \
    "EC2_CUSTOM_AMI_ID=\"${EC2_CUSTOM_AMI_ID}\"\n" \
    | sed -e 's/^[ ]*//' | tee -a $SETUP_AUTO_PATH
    

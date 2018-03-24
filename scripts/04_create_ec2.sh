#!/bin/bash

# Create one AWS EC2 Instance


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# start the machine
echo -e "$INFO Starting an AWS $EC2_INSTANCE_TYPE Instance" \
    "from AMI ID $(FC $EC2_AMI_ID) ..."
EC2_INSTANCE_ID=$(aws $AWS_PRFL ec2 run-instances \
    --region $AWS_REGION \
    --image-id $EC2_AMI_ID \
    --instance-type $EC2_INSTANCE_TYPE \
    --key-name $EC2_KEY_NAME \
    --subnet-id $EC2_SUBNET_ID \
    --security-group-ids $EC2_SECURITY_GROUP_IDS \
    --query 'Instances[0].InstanceId' \
    --output text)
exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo -e "$INFO AWS EC2 Instance ID is: $(FC $EC2_INSTANCE_ID)"
else
    echo -e "$ERROR Cannot create an AWS EC2 Instance. Exiting."
    exit 1
fi


# Wait until the machine is ready
echo -e "$INFO Waiting for the AWS EC2 Instance to initialize ..."
OVER=0
TEST=0
while [ $OVER -eq 0 ] && [ $TEST -lt $EC2_MAX_TESTS ]; do
    EC2_STATE_NAME=$(aws $AWS_PRFL ec2 describe-instances \
        --region $AWS_REGION \
        --instance-ids $EC2_INSTANCE_ID \
        --query Reservations[0].Instances[0].State.Name \
        --output text)
    EC2_DNS_NAME=$(aws $AWS_PRFL ec2 describe-instances \
        --region $AWS_REGION \
        --instance-ids $EC2_INSTANCE_ID \
        --query Reservations[0].Instances[0].PublicDnsName \
        --output text)
    if [[ "$EC2_DNS_NAME" == "" ]]; then
        echo -e "$ERROR Instance $(FC $EC2_INSTANCE_ID) not available" \
            "(crashed or terminated). Exiting."
        exit 1
    fi
    if [[ "$EC2_STATE_NAME" == "running" ]]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds ..."
        sleep 5
    fi
done

if [ $TEST -lt $EC2_MAX_TESTS ]; then
    echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is running," \
        "its address is $(FY $EC2_DNS_NAME)"
else
    echo -e "$ERROR Instance $(FC $EC2_INSTANCE_ID) never got to running" \
        "state. Terminating end exiting ..."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi  


# Wait until SSH server is ready
echo -e "$INFO Waiting for the SSH Server to start ..."
OVER=0
while [ $OVER -eq 0 ] && [ $TEST -lt $EC2_MAX_TESTS ]; do
    
    # a short SSH command that cannot fail
    # since it is the first time we see this sever, store its fingerprint
    ssh -i $EC2_KEY_FILE \
        -o "StrictHostKeyChecking no" \
        -T $EC2_USERNAME@$EC2_DNS_NAME \
        'whoami'
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        OVER=1
    else
        TEST=$(( TEST+1 ))
        echo -e "$INFO Check # $(FC $TEST). Trying again in 5 seconds ..."
        sleep 5
    fi
done

if [ $TEST -lt $EC2_MAX_TESTS ]; then
    echo -e "$INFO Can connect to $(FY $EC2_DNS_NAME)"
else
    echo -e "$ERROR Cannot connect to $(FY $EC2_DNS_NAME)." \
        "Terminating end exiting ..."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi

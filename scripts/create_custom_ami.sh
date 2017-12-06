#!/bin/bash

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"

EC2_AMI_ID="ami-acd005d5"

source "$SCR_DIR/04_create_ec2.sh"
source "$SCR_DIR/10_connect_to_ec2.sh"
source "$SCR_DIR/15_stop_ec2.sh"


EC2_AMI_ID=$(aws ec2 create-image --instance-id $EC2_INSTANCE_ID --name "Custom AMI" --output text)

echo -en "\nEC2_AMI_ID=${EC2_AMI_ID}"|  tee -a ../settings/default_setup.sh
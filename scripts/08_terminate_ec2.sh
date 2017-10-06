#!/bin/bash

# Terminate an Amazon EC2 virtual machine (an instance) 


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# terminate a known instance
if [[ -z $EC2_INSTANCE_ID ]]; then
    echo -e "$ERROR No Instance ID found. Please terminate it using AWS website."
else
    echo -e "$INFO Attempting to terminate Instance $(FC $EC2_INSTANCE_ID)"
    aws $AWS_PRFL ec2 terminate-instances --instance-ids $EC2_INSTANCE_ID --output table
    exit_status=$?
    if [[ $exit_status -eq 0 ]]; then
        echo -e "$INFO Instance $(FC $EC2_INSTANCE_ID) is being terminated."
    else
        echo -e "$ERROR Cannot terminate Instance $(FC $EC2_INSTANCE_ID)." \ 
                "Please terminate it using AWS website console."
    fi
fi

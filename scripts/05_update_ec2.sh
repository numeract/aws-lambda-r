#!/bin/bash

# Update the AWS EC2 Instance (update & install Python, R, packages)


# load local settings if not already loaded 
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


if [[ $EC2_AMI_ID == "$EC2_CUSTOM_AMI_ID" ]]; then
    # custom AMI, skip updating
    echo -e "$INFO Using Custom AMI $(FC $EC2_AMI_ID), skip updating."
else
    # connect to the created instance and update it
    echo -e "$INFO Connecting and Updating EC2 instance ..."
    # hack: colors and $MISSING first by reading from 02_setup.sh
    cat <(head -n 19 "${SCR_DIR}/02_setup.sh") \
            $EC2_SET_1 $EC2_SET_4 $EC2_SCR_11 \
        | ssh -i "$EC2_KEY_FILE" \
            -T "${EC2_USERNAME}@${EC2_DNS_NAME}" \
            'bash -s'
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "$INFO Finished updating EC2 instance."
    else
        echo -e "$ERROR Cannot update EC2 instance $(FC $EC2_INSTANCE_ID)." \
            "Terminating end exiting ..."
        source "$SCR_DIR/08_terminate_ec2.sh"
        exit 1
    fi    
fi

#!/bin/bash

# update the EC2 virtual machine (an instance)


# load local settings if not already loaded 
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# connect to the created instance
cat $EC2_SET_1 $EC2_SET_4 |\
    ssh -i "$EC2_KEY_FILE" \
        -T "${EC2_USERNAME}@${EC2_DNS_NAME}" \
        'bash -s'

exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Finished updating and installing."
else
    echo -e "$ERROR Cannot update EC2 $(FC $EC2_INSTANCE_ID)."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi

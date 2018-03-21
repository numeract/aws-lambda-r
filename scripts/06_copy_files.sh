#!/bin/bash

# copies files to dir lambda/ and then to EC2


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# copy files to local lambda dir
echo -e "$INFO Copy files to local $(FY "$(basename $LAMBDA_DIR)/")"

# read the list of files, use grep to skip empty lines
LAMBDA_FILES=( $(cat "$SET_DIR/lambda_files.txt" | grep -v "^\s*$") )

# copy lambda files from different dir to only one dir
for i in "${LAMBDA_FILES[@]}"
do
    echo -e "$INFO Copy file: $i to "$(basename $LAMBDA_DIR)/""
    cp "$PRJ_DIR/$i" "$LAMBDA_DIR"
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        break
    fi
done
if [ $exit_status -ne 0 ]; then
    echo -e "$ERROR Failed to copy all files to $(FY "$(basename $LAMBDA_DIR)/")" \
        "Terminating end exiting ..."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi


# delete `~/${PRJ_NAME} to start with a clean copy
echo -e "$INFO Remove EC2 directory $(FY '~/'$PRJ_NAME)"
ssh -i "$EC2_KEY_FILE" \
    -T "${EC2_USERNAME}@${EC2_DNS_NAME}" \
    "sudo rm -rf ~/${PRJ_NAME}"


# copy files from local lambda dir to EC2
echo -e "$INFO Copying local $(FY "$(basename $LAMBDA_DIR)/") to" \
    "EC2 $(FY '~/'$PRJ_NAME) ..."
scp -i "$EC2_KEY_FILE" \
    -r "$LAMBDA_DIR" \
    "${EC2_USERNAME}@${EC2_DNS_NAME}:~/${PRJ_NAME}"
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo -e "$ERROR Failed to copy $(FY "$(basename $LAMBDA_DIR)/") to EC2." \
        "Terminating end exiting ..."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi

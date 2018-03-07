#!/bin/bash

# copies files to dir lambda/ and then to EC2


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# read the list of files, use grep to skip empty lines
LAMBDA_FILES=( $(cat "$SET_DIR/lambda_files.txt" | grep -v "^\s*$") )

# copy lambda files from different dir to only one dir
for i in "${LAMBDA_FILES[@]}"
do
    echo -e "$INFO Copy file: $i to "$(basename $LAMBDA_DIR)"/"
    cp "$PRJ_DIR/$i" "$LAMBDA_DIR"
    exit_status=$?
    if [[ $exit_status != 0 ]]; then
        break
    fi
done
if [[ $exit_status != 0 ]]; then
    echo -e "$ERROR Cannot copy all files. Exiting."
    exit 1
fi

# copy files to EC2
echo -e "$INFO Copy local $(FY $LAMBDA_DIR) to EC2 $(FY '~/'$PRJ_NAME)"

scp -i "$EC2_KEY_FILE" \
    -r "$LAMBDA_DIR" \
    "${EC2_USERNAME}@${EC2_DNS_NAME}:~/${PRJ_NAME}"
exit_status=$?
if [[ $exit_status != 0 ]]; then
    echo -e "$ERROR Cannot copy lambda files to EC2. Exiting."
    exit 1
fi

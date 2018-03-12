#!/bin/bash

# calls all other local scripts 


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


source "$SCR_DIR/03_check_settings.sh"

source "$SCR_DIR/04_create_ec2.sh"

source "$SCR_DIR/05_update_ec2.sh"

source "$SCR_DIR/06_copy_files.sh"

source "$SCR_DIR/07_deploy_lambda.sh"

source "$SCR_DIR/08_terminate_ec2.sh"

source "$SCR_DIR/09_test_deployment.sh"


echo -e "$INFO End of $(basename $0) script"

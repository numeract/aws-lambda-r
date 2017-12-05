#/!bin/bash

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"



source "$SCR_DIR/00_aws_setup.sh"

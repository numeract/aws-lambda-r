#!/bin/bash

# Run first (before other .sh scripts) in order to export the filename 
# containing user specific setting / secret variables.

# The default name for this file is `setup_user_secrets.sh`.
# However, the default file cannot be tracked by git as it is user specific.

# If you do not have the `setup_user_secrets.sh` file in this folder:
# 1. make a copy of this file, rename it `setup_user_secrets.sh`
# 2. in `setup_user_secrets.sh` edit the line below


USER_SECRETS_FILE="<user_secrets_file_name>.sh"

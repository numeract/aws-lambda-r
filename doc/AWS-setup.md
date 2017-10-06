# aws-lambda-r - Configure AWS for production deployment

**Note: the detailed instructions are not complete.** If you are familiar with AWS,
please review the files in `scripts/` and `settings/`.

These are instructions to be followed before running the scripts. At the end of 
these instruction you should have obtained the values for the following keys:

```
IAM_ACCESS_KEY_ID=""
IAM_SECRET_ACCESS_KEY=""
IAM_LAMBDA_FUNCTION_ROLE=""
EC2_KEY_NAME=""
EC2_KEY_FILE=""
EC2_SECURITY_GROUP_IDS=""
EC2_SUBNET_ID=""
S3_BUCKET=""
API_ID=""
API_RESOURCE_ID=""
API_ALIAS_RESOURCE_ID=""
API_AUTHORIZER_ID=""
API_TOKEN=""
```




## IAM 

IAM manages access to AWS.

1. Create an IAM user account to be used only in conjunction with this app
  + retain the values of **ACCESS_KEY_ID** and **SECRET_ACCESS_KEY**
2. Give necessary permissions to this user
  + [TBD: more automation --> more permissions]
3. Create roles and policies 
  + attach policies to the roles


## SSH Key

SSH Keys allows access through an SSH tunnel to a remove / cloud AWS EC2 instance.

### Create and save SSH key for EC2 connection

1. Log in to AWS Console.
2. Go to EC2 Service
3. Select **Key Pairs** under **NETWORK & SECURITY** menu. 

![Key Pairs menu](ssh-01-key-pairs-menu.png)

4. Press "Create Key Pair" button and give it a name. When you press the 
"Create" button, the browser will start downloading the key automatically.

![Enter key pair name](ssh-02-enter-key-pair-name.png)

5. Open the folder containing downloaded key (a `.pem` file having the same name as the created key)

6. Copy the `.pem` file to:
    - on Windows: `C:\Users\<your_user_Name>/.ssh/` folder 
        + in order to show hidden folders go to Folder Menu > View > Check "Hidden items"
    - on OSX and Linux: `~/.ssh/` Additional commands might be necessary from terminal:
        + `chmod 700 ~/.ssh`
        + `chmod 400 ~/.ssh/<your_key_file>.pem`
        + other instructions: [1](https://unix.stackexchange.com/a/115860) and 
        [2](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)


## VPC [automate ?]

1. Create dedicate VPC 
2. Create subnet
3. Create security group


## LAMBDA [automate ?]

1. Create Lambda Authorizer function 


##  S3 BUCKET [automate ?]

1. Create S3 bucket


## API GATEWAY

1. Create API
2. Create resources
3. Create authorizer
4. Create stages
5. Attach role for CloudWatch logging to API
6. Enable CloudWatch Logging on stages


## TERMINATE UNUSED INSTANCES

1. Go to AWS web console and select Frankfurt / eu-central-1 region
2. To to EC2 > Instances
3. Select all running instance > Actions button > Instance State > Terminate

## Create Custom Settings file

[steps needed to create "secrets_user.sh" and "setup_user_secrets.sh" files]

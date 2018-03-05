# aws-lambda-r - Configure AWS for production deployment

**Note: these instructions are not complete.** If you are already familiar with AWS,
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

1. Create an IAM user account to be used only in conjunction with these scripts
    + retain the values of **ACCESS_KEY_ID** and **SECRET_ACCESS_KEY**
2. Give necessary permissions to this user
    + in general more automation requires more permissions
    + TBD
3. Create roles and policies 
    + attach policies to the roles
    + TBD


## SSH Key

SSH Keys allows access through an SSH tunnel to an AWS EC2 instance.

### Create and save SSH key for EC2 connection

1. Log in to AWS Console.
2. Go to EC2 Service
3. Select **Key Pairs** under **NETWORK & SECURITY** menu. 

![Key Pairs menu](21-ssh-key-pairs-menu.png)

4. Press "Create Key Pair" button and give the key a name. When you press the 
"Create" button, the browser will download the key.

![Enter key pair name](22-ssh-enter-key-pair-name)

5. Open the folder containing downloaded key (a `.pem` file having the same name as the created key)

6. Copy the `.pem` file to:
    - on Windows: `C:\Users\<your_user_Name>/.ssh/` folder 
        + in order to show hidden folders go to Folder Menu > View > Check "Hidden items"
    - on OSX and Linux: `~/.ssh/` 
        + Additional commands might be necessary from terminal:
        + `chmod 700 ~/.ssh`
        + `chmod 400 ~/.ssh/<your_key_file>.pem`
        + other instructions: [1](https://unix.stackexchange.com/a/115860) and 
        [2](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)


## VPC

### Create dedicated VPC 

1. Go to AWS Console
2. Select VPC from Services menu
3. From VPC Dashboard, click "Start VPC Wizard".

![VPC Dashboard](31-create-vpc.PNG)

4. Choose "VPC with a Single Public Subnet" and click the "Select" button.

!["Create VPC" button](32-create-vpc.PNG)

5. Fill VPC name and Subnet name fields. 

![Edit fields](33-create-vpc.jpg)

6. Click the "Create VPC" button.

### Edit subnet

1. Go to AWS Console
2. Select VPC from Services menu
3. From VPC Dashboard, Virtual Private Cloud section, select "Subnets"
4. Select the subnet previously created.
5. From "Subnet Actions" menu, select "Modify auto-assign IP settings" option.

![Edit Subnet1](34-edit-subnet.PNG)

6. Check "Enable auto-assign public IPv4 address".

![Edit Subnet2](35-edit-subnet.PNG)

## Create security group

1. Go to AWS Console
2. Select VPC from Services menu
3. From VPC Dashboard,Virtual Private Cloud section, select "Security Groups".
4. Click the "Create Security Group" button.


## LAMBDA

### Create Lambda Authorizer function (automated, see `aws_setup.sh` script)


##  S3 BUCKET

### Create S3 bucket (automated, see `aws_setup.sh` script)


## API GATEWAY

1. Create API (automated, see `aws_setup.sh` script)
2. Create resources (automated, see `aws_setup.sh` script)
3. Create authorizer (automated, see `aws_setup.sh` script)
4. Create stages  
5. Attach role for CloudWatch logging to API
6. Enable CloudWatch Logging on stages


## TERMINATE UNUSED INSTANCES

1. Go to AWS web console and select a region, e.g., Frankfurt / eu-central-1 region
2. To to EC2 > Instances
3. Select all running instance > Actions button > Instance State > Terminate

## DELETE SERVICES

### VPC

1. Go to AWS Console
2. Select VPC from Services menu
3. From VPC Dashboard,Virtual Private Cloud section, select "Your VPC's"
4. Select the VPC you want to delete
5. Click the "Actions" button 

![Delete VPC](vpc-delete.PNG)

6. Select "Delete VPC" option

### Subnet

1. Go to AWS Console
2. Select VPC from Services menu
3. From VPC Dashboard, Virtual Private Cloud section, select "Subnets"
4. Select the subnet you want to delete
5. Click on "Actions" button 

![Delete Subnet](subnet-delete.PNG)

6. Select "Delete Subnet" option

## Service Role
1. Go to AWS Console
2. Select IAM from Services menu
3. From IAM Dashboard, select "Roles"

![IAM Dashboard](role-01-delete.PNG)

4. Select the role you want to delete 

![IAM Roles](role-02-delete.PNG)

5. Click on "Delete role" button

## Lambda Function
1. Go to AWS Console
2. Select Lambda from Services menu
3. Select "Functions" from AWS Lambda menu
4. Select the function you want to delete 

![Lambda Functions](delete_lambda.PNG)

5. Click on "Delete" button

## S3 Bucket
1. Go to AWS Console
2. Select S3 from Services menu
3. Select the bucket you want to delete

![S3 Buckets](S3-delete.PNG)

4. Click the "Delete bucket" button

## API
1. Go to AWS Console
2. Select API Gateway from Services menu
3. Select the API you want to delete
4. Click the "Actions" button
5. Select "Delete API" option

![Delete API](delete_api.PNG)

## API Resources
1. Go to the API that contains the resource you want to delete
2. Select the resource you want to delete
4. Click the "Actions" button
5. Select "Delete Resource" option

![Delete API resource](delete_resources.PNG)

## API Authorizers
1. Go to the API that contains the authorizer you want to delete
2. Select "Authorizers" from the API's menu

![API menu](delete_authorizer1.PNG)

3. Click on "Delete Authorizer" button placed in the right corner of 
authorizer description section 

![Delete authorizer](delete_authorizer2.PNG)


# Create Custom Settings file

[steps needed to create "secrets_user.sh" and "setup_user_secrets.sh" files]

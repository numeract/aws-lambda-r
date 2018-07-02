# Using R on AWS Lambda


### Summary

This repo contains several scripts that facilitate execution of R functions on 
AWS Lambda.

Currently (March 2018) it is not possible to run R code directly on AWS Lambda,
thus we need to invoke it through Python.

The scripts:

- use your settings to create an AWS EC2 instance, 
- install and compile R packages
- create the zip file to load in AWS Lambda and save it to S3
- create Lambda function and deploy the zip file
- configure AWS API Gateway to allow accessing the code over the web

At the end of the setup, you will have a AWS Lambda function that can be invoked
as many times as you wish trough AWS API Gateway, without worrying about EC2 instances or scalability issues.


### Scope

The best use case of this setup is 

- almost unlimited scalability (1000 concurrent executions)
- no idle server time 
- very low cost
- R functions are small and execute fast
- input and output through JSON strings


### Limitations

AWS Lambda and API Gateway impose several limitations

- maximum memory 3008MB 
    + this should be sufficient to run most functions
- maximum zip file size 250MB 
    + this is the most important limitation as it prevents using large R packages
- maximum execution time 30 seconds for API Gateway, 5 minutes for AWS Lambda
    + be sure to take allow 1-2 sec for start time


### Description

**The current setup assumes that the following directories and their content
will be added to your R project directory.**

- `lambda/` : a temporary directory with files to be uploaded
- `python/` : contains Python files, one for each AWS Lambda entry point, 
that will be used to invoke the R code
- `scripts/` : the scripts compiling R packages and deploying to AWS Lambda
- `settings/` : settings files used for deployment (e.g. where to find AWS settings)

Directory `doc/` contains additional documentation about how to setup for your 
AWS account (although familiarity with AWS helps a lot) and how to delete the 
setup created by these scripts.


### Installation and configuration

1. Install [AWS CLI](https://aws.amazon.com/cli/) on your local machine
    + Be sure that you stored your credentials in `~/.aws/` directory
    + Optionally, create a profile for AWS CLI with [aws configure --profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
    + Check that you can connect to your AWS account using the desired profile
        + `aws sts get-caller-identity --profile aws-lambda-r`
2. Prepare your project
    + Ideally, the project directory name should contain only letters, dashes, and digits, e.g. `aws-lambda-r`
    + Be sure that git is initialized in the project directory (without git it 
    will be almost impossible to keep track of changes, especially in production)
        + `git status`
3. Copy directories `lambda/`, `python/`, `scripts/`, `settings/` to your project directory
4. Copy and rename `setup_auto_example.sh` and `setup_user_example.sh` to 
`setup_auto.sh` and `setup_user.sh` 
5. Overwrite variables from `secrets_default.sh` and `setup_default` with 
personal secrets in `setup_user.sh`. Variables such as `PRJ_NAME`, `PRJ_BRANCH`, 
`AWS_REGION` and `EC2_DEFAULT_AMI_ID` from `settings_default.sh` 
should be overwritten accordingly in `setup_user.sh`.
6. For automated AWS infrastructure setup run first `21_setup_vpc.sh`, 
`22_setup_custom_ami.sh`, `23_setup_s3.sh` and `24_setup_lambda.sh`, 
otherwise create the infrastructure manually, following the documentation.


###  macOS additional steps

Install the following packages, if not already installed:

1. [**Homebrew**](https://brew.sh)

`$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

2. [**Bash 4**](http://tldp.org/LDP/abs/html/bashver4.html)

`$ brew update && brew install bash`

3. Add **Bash 4** as the default shell:

```
$ sudo nano /etc/shells

# add to last line
/usr/local/bin/bash

# save and quit via ctrl + x
```

4. **md5sum**:

`$ brew install md5sha1sum`

Load all the scripts via `sudo bash ./scripts/<script_name>.sh` instead of 
`.scripts/<script_name>.sh`.


### References

- [Analyzing Genomics Data at Scale using R, AWS Lambda, and Amazon API Gateway](https://aws.amazon.com/blogs/compute/analyzing-genomics-data-at-scale-using-r-aws-lambda-and-amazon-api-gateway/)
- [Running R on AWS](https://aws.amazon.com/blogs/big-data/running-r-on-aws/)
- [Lambda Execution Environment and Available Libraries](https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html)
- [AWS Lambda limits](https://docs.aws.amazon.com/lambda/latest/dg/limits.html)


### TODO

- use AWS Cloud​Formation to create a template for all AWS config
    + see "Running R on AWS"
- script to check AWS CLI is properly installed
- convert to an R package and execute the scripts from R
- use `/tmp` folder on AWS Lambda to load large libraries (e.g., `BH`)

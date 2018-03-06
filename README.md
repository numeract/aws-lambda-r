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
- other [AWS Lambda limits](https://docs.aws.amazon.com/lambda/latest/dg/limits.html)


### Description

**The current setup assumes that the following directories and their content
will be added to your R project directory.**

- `lambda/` : a temporary directory with files to be uploaded
- `python/` : contains Python files, one for each AWS Lambda entry point, 
that will be used to invoke the R code
- `scripts/` : the scripts compiling R packages and deploying to AWS Lambda
- `settings/` : settings files used for deployment (e.g. where to find AWS settings)

Directory `doc/` contains additional documentation about how to setup for your AWS
account (although familiarity with AWS helps a lot) and how to delete the setup created by these scripts.



### Installation and configuration

1. Be sure that you have AWS CLI properly installed on your machine
2. Copy directories `lambda/`, `python/`, `scripts/`, `settings/` to your project
3. [TODO]


### References

[TODO]



### TODO

- script to check AWS CLI is properly installed
- convert to an R package and execute the scripts from R
- use `/tmp` folder on AWS Lambda to load large libraries (e.g., `BH`)

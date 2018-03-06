#!/bin/bash

# check if VPC exists given the config variables, create it if not

# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# Creating S3 Bucket
aws $AWS_PRFL s3api create-bucket \
    --bucket ${S3_BUCKET} \
    --region ${AWS_REGION} \
    --create-bucket-configuration LocationConstraint=${AWS_REGION}



# Creating Lambda Authorizer Function
 
sleep 10
echo -e "$INFO Creating lambda function."
aws $AWS_PRFL lambda create-function \
    --region ${AWS_REGION} \
    --function-name ${LAMBDA_AUTHORIZER_NAME} \
    --zip-file fileb://../doc/index.zip \
    --role ${LAMBDA_ROLE_ARN} \
    --handler index.handler \
    --runtime nodejs6.10 \
    --output table

# Extracting the lambda function ARN

LAMBDA_AUTHORIZER_ARN="$(aws $AWS_PRFL lambda list-functions \
    --query "Functions[?FunctionName==\`${LAMBDA_AUTHORIZER_NAME}\`].FunctionArn" \
    --output text \
    --region ${AWS_REGION})"


# Creating API
aws $AWS_PRFL apigateway create-rest-api \
    --name $API_GATEWAY_NAME \
    --output table

# Getting API id
API_ID="$(aws $AWS_PRFL apigateway get-rest-apis \
    --query "items[?name==\`${API_GATEWAY_NAME}\`].id" \
    --output text)"



# Getting API root resource id

ROOT_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/\`].id" \
    --output text)"
                    


# Creating Resource

aws $AWS_PRFL apigateway create-resource \
    --rest-api-id ${API_ID} \
    --parent-id ${ROOT_RESOURCE_ID} \
    --path-part ${API_RESOURCE_NAME} \
    --output table

API_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/${API_RESOURCE_NAME}\`].id" \
    --output text)"

# Creating Alias Resource
aws $AWS_PRFL apigateway create-resource \
    --rest-api-id ${API_ID} \
    --parent-id ${ROOT_RESOURCE_ID} \
    --path-part ${API_ALIAS_RESOURCE_NAME} \
    --output table

API_ALIAS_RESOURCE_ID="$(aws $AWS_PRFL apigateway get-resources \
    --rest-api-id ${API_ID} \
    --query "items[?path==\`/${API_ALIAS_RESOURCE_NAME}\`].id" \
    --output text)"

# Creating Authorizer
aws $AWS_PRFL apigateway create-authorizer 
    --rest-api-id ${API_ID} \
    --name ${AUTHORIZER_NAME} \
    --type TOKEN --authorizer-uri 'arn:aws:apigateway:'${AWS_REGION}':lambda:path/2015-03-31/functions/'${LAMBDA_AUTHORIZER_ARN}'/invocations' \
    --identity-source 'method.request.header.Auth' \
    --authorizer-result-ttl-in-seconds 300 \
    --output table
                                 

AUTHORIZER_ID="$(aws $AWS_PRFL apigateway get-authorizers \
    --rest-api-id ${API_ID} \
    --query "items[?name==\`${AUTHORIZER_NAME}\`].id" \
    --output text)"                              

API_ARN=$(echo ${LAMBDA_AUTHORIZER_ARN} | \
    sed -e 's/lambda/execute-api/' \
    -e "s/function:${LAMBDA_AUTHORIZER_NAME}/${API_ID}/")
 
# Adding permissions for authorizer invocation 
aws $AWS_PRFL lambda add-permission \
    --function-name ${LAMBDA_AUTHORIZER_ARN} \
    --source-arn ${API_ARN}/authorizers/${AUTHORIZER_ID} \
    --principal apigateway.amazonaws.com \
    --statement-id ${PRJ_NAME}_stmt \
    --action lambda:InvokeFunction
           
# Adding permissions for API logging

echo -e "$INFO Creating VPC and security group"

#  Create a non-default VPC with an IPv4 CIDR block
VPC_ID=$(aws $AWS_PRFL ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' \
    --output text)

# Enable public DNS host names for VPC instances        
aws $AWS_PRFL ec2 modify-vpc-attribute \
    --vpc-id ${VPC_ID} \
    --enable-dns-support "{\"Value\":true}"

aws $AWS_PRFL ec2 modify-vpc-attribute \
    --vpc-id ${VPC_ID} \
    --enable-dns-hostnames "{\"Value\":true}"

# Create public subnet with a 10.0.1.0/24 CIDR block.  
SUBNET1_ID=$(aws $AWS_PRFL ec2 create-subnet \
    --vpc-id  ${VPC_ID} \
    --cidr-block 10.0.1.0/24 \
    --query 'Subnet.SubnetId' \
    --output text)
            
# Create private subnet with a 10.0.0.0/24 CIDR block.
SUBNET2_ID=$(aws $AWS_PRFL ec2 create-subnet \
    --vpc-id  ${VPC_ID} \
    --cidr-block 10.0.0.0/24 \
    --query 'Subnet.SubnetId' \
    --output text)

 # Create an Internet gateway for public subnet           
GATEWAY_ID=$(aws $AWS_PRFL ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

# Making subnet public by attaching an Internet gateway to VPC
aws $AWS_PRFL ec2 attach-internet-gateway \
    --vpc-id ${VPC_ID} \
    --internet-gateway-id ${GATEWAY_ID}
        
# Create a custom route table for VPC
ROUTE_TABLE_ID=$(aws $AWS_PRFL ec2 create-route-table \
    --vpc-id ${VPC_ID}\
    --query 'RouteTable.RouteTableId'\
    --output text)

# Create a route in the route table that points
# all traffic (0.0.0.0/0) to the Internet gateway                
aws $AWS_PRFL ec2 create-route \
    --route-table-id ${ROUTE_TABLE_ID} \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id ${GATEWAY_ID}
        
# Associate subnet with custom route table
# in order to make it public       
ASSOCIATION_ID=$(aws $AWS_PRFL ec2 associate-route-table \
    --subnet-id ${SUBNET1_ID} \
    --route-table-id ${ROUTE_TABLE_ID} \
    --query 'AssociationId' \
    --output text)   

# Modify the public IP addressing behavior of subnet  
# so that subnet automatically receives a public IP address              
aws $AWS_PRFL ec2 modify-subnet-attribute \
    --subnet-id ${SUBNET1_ID} \
    --map-public-ip-on-launch 
        
# Create a security group in VPC       
SECURITY_GROUP_ID=$(aws $AWS_PRFL ec2 create-security-group \
    --group-name EC2access \
    --description "Security group for SSH access" \
    --vpc ${VPC_ID} \
    --query 'GroupId' \
    --output text)
                    
 # Add a rule that allows SSH access from anywhere                
aws $AWS_PRFL ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Writing variables in default_setup.sh
echo -en \
    "IAM_LAMBDA_FUNCTION_ROLE=${LAMBDA_ROLE_ARN}\n" \
    "API_ID=${API_ID}\n" \
    "API_AUTHORIZER_ID=${AUTHORIZER_ID}\n" \
    "API_ARN=${API_ARN}\n" \
    "API_RESOURCE_ID=${API_RESOURCE_ID}\n" \
    "API_ALIAS_RESOURCE_ID=${API_ALIAS_RESOURCE_ID}\n" \
    "EC2_SUBNET_ID=${SUBNET1_ID}\n" \
    "EC2_SECURITY_GROUP_IDS=${SECURITY_GROUP_ID}\n" \
    "VPC_ID=${VPC_ID}" | tee ../settings/default_setup.sh

echo -e "$INFO Lambda role ARN is: $(FY $LAMBDA_ROLE_ARN) "
echo -e "$INFO LAMBDA_AUTHORIZER_ARN is: $(FY $LAMBDA_AUTHORIZER_ARN)"
echo -e "$INFO API ID is: $(FY $API_ID)"
echo -e "$INFO API ROOT_RESOURCE_ID is: $(FY $ROOT_RESOURCE_ID)"
echo -e "$INFO API_RESOURCE_ID is: $(FY $API_RESOURCE_ID) "
echo -e "$INFO AUTHORIZER_ID is: $(FY $AUTHORIZER_ID)"
echo -e "$INFO API_ARN is: $(FY $API_ARN)"

echo -e "$INFO VPC id is: $(FY $VPC_ID) "
echo -e "$INFO SUBNET1_ID is: $(FY $SUBNET1_ID)"
echo -e "$INFO SECURITY_GROUP_ID is: $(FY $SECURITY_GROUP_ID)"

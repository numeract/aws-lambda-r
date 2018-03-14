#!/bin/bash

# check if VPC exists given the config variables, create it if not


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


echo -e "$INFO Creating VPC and Security Group......"

set -e 

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
    --vpc-id ${VPC_ID} \
    --cidr-block 10.0.1.0/24 \
    --query 'Subnet.SubnetId' \
    --output text)

# Create private subnet with a 10.0.0.0/24 CIDR block.
SUBNET2_ID=$(aws $AWS_PRFL ec2 create-subnet \
    --vpc-id ${VPC_ID} \
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
# TODO: proper group-name, description (cannot be modified later)
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

# append to setup_auto.sh
echo -e "$INFO Appending to $(FY $(basename $SETUP_AUTO_PATH)):"
echo -en \
    "\n # Added on: $(date -u '+%Y-%m-%d %H:%M:%S %Z')\n" \
    "EC2_SUBNET_ID=\"${SUBNET1_ID}\"\n" \
    "EC2_SECURITY_GROUP_IDS=\"${SECURITY_GROUP_ID}\"\n" \
    | sed -e 's/^[ ]*//' | tee -a $SETUP_AUTO_PATH
    
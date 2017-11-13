#/!bin/bash

# variable & functions to display messages
INFO="\e[32mINFO :\e[39m"                               # Green
WARN="\e[33mWARN :\e[39m"                               # Yellow
ERROR="\e[31mERROR:\e[39m"                              # Red
MISSING="\e[95mMISSING\e[39m"                           # Magenta

FY () { echo -e "\e[33m$1\e[39m"; }                     # Foreground Yellow
FC () { echo -e "\e[36m$1\e[39m"; }                     # Foreground Cyan
BY () { echo -e "\e[43m\e[30m$1\e[39m\e[49m"; }         # Background Yellow

VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --query 'Vpc.VpcId' \
        --output text)
        
aws ec2 modify-vpc-attribute \
        --vpc-id ${VPC_ID} \
        --enable-dns-hostnames
        
SUBNET1_ID=$(aws ec2 create-subnet \
            --vpc-id  ${VPC_ID} \
            --cidr-block 10.0.1.0/24 \
            --query 'Subnet.SubnetId' \
            --output text)
            

SUBNET2_ID=$(aws ec2 create-subnet \
            --vpc-id  ${VPC_ID} \
            --cidr-block 10.0.0.0/24 \
            --query 'Subnet.SubnetId' \
            --output text)
            
GATEWAY_ID=$(aws ec2 create-internet-gateway \
             --query 'InternetGateway.InternetGatewayId' \
             --output text)

aws ec2 attach-internet-gateway \
        --vpc-id ${VPC_ID} \
        --internet-gateway-id ${GATEWAY_ID}

ROUTE_TABLE_ID=$(aws ec2 create-route-table \
                --vpc-id ${VPC_ID}\
                --query 'RouteTable.RouteTableId'\
                --output text)
                
aws ec2 create-route \
        --route-table-id ${ROUTE_TABLE_ID} \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id ${GATEWAY_ID}
        
        
ASSOCIATION_ID=$(aws ec2 associate-route-table \
                --subnet-id ${SUBNET1_ID} \
                --route-table-id ${ROUTE_TABLE_ID} \
                --query 'AssociationId' \
                --output text)   
                
aws ec2 modify-subnet-attribute \
        --subnet-id ${SUBNET1_ID} \
        --map-public-ip-on-launch        
        
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
                    --group-name EC2access \
                    --description "Security group for SSH access" \
                    --vpc ${VPC_ID} \
                    --query 'GroupId' \
                    --output text)

echo -en "EC2_SUBNET_ID=${SUBNET1_ID}\nEC2_SECURITY_GROUP_IDS=" \
         "${SECURITY_GROUP_ID}\nVPC_ID=${VPC_ID}" |  tee ../settings/default_vpc.sh                    

echo -e "$INFO VPC id is: $(FY $VPC_ID) "
echo -e "$INFO SUBNET1_ID is: $(FY $SUBNET1_ID)"
echo -e "$INFO SECURITY_GROUP_ID is: $(FY $SECURITY_GROUP_ID)"
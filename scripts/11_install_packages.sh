#!/bin/bash

# run on EC2 to update and install packages
# optionally, create a new AMI to skip this step

# variable used to inform
INFO="\e[32mINFO :\e[39m"                               # Green

# update instance
echo -e "$INFO Making sure everything is up-to-date ..."
sudo yum -y update
sudo yum -y upgrade


# install 
echo -e "$INFO Installing python34 and R."
sudo yum install -y python34-devel python34-pip gcc gcc-c++ readline-devel libgfortran.x86_64 R.x86_64 wget

echo -e "$INFO Installing git, mysql, blas, lapack."
sudo yum install -y git-all mysql-devel blas lapack


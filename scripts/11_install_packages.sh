#!/bin/bash

# run on EC2 to update and install packages
# optionally, create a new AMI to skip this step

# variable used to inform
INFO="\e[32mINFO :\e[39m"                               # Green

# update instance
echo -e "$INFO Making sure everything is up-to-date ..."
sudo yum -y update
sudo yum -y upgrade
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# install Linux packages
# TODO: install python 3.7
echo -e "$INFO Installing gcc, python36 and R ..."
sudo yum install -y \
    gcc gcc-c++ \
    readline-devel libgfortran.x86_64 \
    python3-3.7.9-1.amzn2.0.2.x86_64 \
    R.x86_64 

echo -e "$INFO Installing other Linux packages ..."
# sudo yum install -y git-all
# sudo yum install -y wget
sudo yum install -y blas lapack

# uncomment the following line in case mysql is needed 
# sudo yum install -y mysql-devel

# add other Linux packages as needed by R packages
# be sure to check their size

# install R packages
echo -e "$INFO Creating the R library directory and setting permissions ..."
cd ~/
sudo mkdir library
sudo chmod -R a+w ~/library

function join_by { local IFS="$1"; shift; echo "$*"; }
echo $(which Rscript)

R_PACKAGES_Q=$(printf "'%s' " "${R_PACKAGES[@]}")
R_PACKAGES_INSTALL=$(join_by , $R_PACKAGES_Q)
if [[ "$R_PACK_INSTALL" == "''" ]]; then
    echo -e "$WARN No R packages found, not installing any R packages."
else
    echo -e "$INFO Installing R packages: ${R_PACKAGES_INSTALL}"
    sudo Rscript -e 'install.packages(c('${R_PACKAGES_INSTALL}'), lib="/home/ec2-user/library", repos="http://cran.us.r-project.org", quiet=TRUE)'
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "$INFO R Packages installation finished."
    else
        echo -e "$ERROR R Packages installation failed."
        exit 1
    fi
fi

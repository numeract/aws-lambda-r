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
echo -e "$INFO Installing python36 and R."
sudo yum install -y python36-devel.x86_64 python36-virtualenv.noarch gcc gcc-c++ readline-devel libgfortran.x86_64 R.x86_64 wget

echo -e "$INFO Installing git, mysql, blas, lapack."
sudo yum install -y git-all mysql-devel blas lapack


virtualenv -p python3.6 ~/env
source ~/env/bin/activate

sudo ~/env/bin/pip3.6 install rpy2 -t ~/env/lib64/python3.6/site-packages
deactivate


cd ~/
sudo mkdir library
echo -e "$INFO PWD: $(pwd)"
sudo chmod -R a+w ~/library
echo -e "$INFO changed permissions"

# Run R script to install packages in project directory
function join_by { local IFS="$1"; shift; echo "$*"; }

R_PACKAGES_Q=$(printf "'%s' " "${R_PACKAGES[@]}")
R_PACK_INSTALL=$(join_by , $R_PACKAGES_Q)
if [[ "$R_PACK_INSTALL" == "''" ]]; then
    echo -e "$WARN No R packages found, not installing any R packages."
else
    echo -e "$INFO Installing R packages: ${R_PACK_INSTALL}"
    sudo Rscript -e 'install.packages(c('${R_PACK_INSTALL}'), lib="/home/ec2-user/library", repos="http://cran.us.r-project.org", quiet=TRUE)'
    echo -e "$INFO R Packages install finished."
fi

#!/bin/bash

# run on EC2 to create deployment package


# prep folder
echo -e "$INFO Creating deployment package"
sudo chmod -R a+w ~/${PRJ_NAME}
cd ~/${PRJ_NAME}



# Python 3 packages transfer (in case Lambda runtime is going to be python3.6)

# virtualenv -p python3 ~/env && source ~/env/bin/activate 
# pip3 install rpy2
# pip3 install jinja2
# sudo cp -r ${CP_VERBOSE}  $VIRTUAL_ENV/lib/python3.4/dist-packages/* ~/${PRJ_NAME}
# sudo cp -r ${CP_VERBOSE}  $VIRTUAL_ENV/lib/python3.4/site-packages/* ~/${PRJ_NAME}
# sudo cp -r ${CP_VERBOSE}  $VIRTUAL_ENV/lib64/python3.4/site-packages/* ~/${PRJ_NAME}
# sudo cp -r ${CP_VERBOSE}  $VIRTUAL_ENV/lib64/python3.4/dist-packages/* ~/${PRJ_NAME}
# deactivate


# Python 2 packages transfer (for Lambda runtime python2.7)
echo -e "$INFO Install and copy rpy2 package+dependencies into project directory"
virtualenv ~/env && source ~/env/bin/activate

echo
pip install --upgrade pip
pip install rpy2==2.8.4
echo

cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib64/python2.7/dist-packages/rpy2* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib64/python2.7/dist-packages/singledispatch* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib64/python2.7/dist-packages/six* ~/${PRJ_NAME}

cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib64/python2.7/site-packages/rpy2* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib64/python2.7/site-packages/singledispatch* ~/${PRJ_NAME}
cp -vr $VIRTUAL_ENV/lib64/python2.7/site-packages/six* ~/${PRJ_NAME}

cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/dist-packages/rpy2* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/dist-packages/singledispatch* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/dist-packages/six* ~/${PRJ_NAME}

cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/site-packages/rpy2* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/site-packages/singledispatch* ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} $VIRTUAL_ENV/lib/python2.7/site-packages/six* ~/${PRJ_NAME}

deactivate


# Copy R needed libraries into project directory
echo
echo -e "$INFO Copy R libraries into project directory."
ls /usr/lib64/R | \
    grep -v library | \
    xargs -I '{}' \
    cp -r ${CP_VERBOSE} /usr/lib64/R/'{}' ~/${PRJ_NAME}/

cp -r ${CP_VERBOSE} /usr/lib64/R/library ~/${PRJ_NAME}/library/

ldd /usr/lib64/R/bin/exec/R | \
    grep "=> /" | \
    awk '{print $3}' | \
    grep 'libgomp.so.1\|libgfortran.so.3\|libquadmath.so.0\|libtre.so.5' | \
    xargs -I '{}' cp ${CP_VERBOSE} '{}' ~/${PRJ_NAME}/lib/

echo -e "$INFO R libraries copy finished."

echo -e "$INFO PWD: $(pwd)"
sudo chmod -R a+w ~/${PRJ_NAME}/library
echo -e "$INFO changed permissions"


# Run R script to install packages in project directory
function join_by { local IFS="$1"; shift; echo "$*"; }

R_PACKAGES_Q=$(printf "'%s' " "${R_PACKAGES[@]}")
R_PACK_INSTALL=$(join_by , $R_PACKAGES_Q)
if [[ "$R_PACK_INSTALL" == "''" ]]; then
    echo -e "$WARN No R packages found, not installing any R packages."
else
    echo -e "$INFO Installing R packages: ${R_PACK_INSTALL}"
    sudo Rscript -e 'install.packages(c('${R_PACK_INSTALL}'), lib="/home/ec2-user/'${PRJ_NAME}'/library", repos="http://cran.us.r-project.org", quiet=TRUE)'
    echo -e "$INFO R Packages install finished."
fi


# Organizing libraries for deployment package
sudo cp ~/${PRJ_NAME}/bin/exec/R ~/${PRJ_NAME}
cp /usr/lib64/libblas.so.3 ~/${PRJ_NAME}/lib
cp /usr/lib64/liblapack.so.3 ~/${PRJ_NAME}/lib
cp /usr/lib64/mysql/libmysqlclient.so.18.0.0 ~/${PRJ_NAME}/lib
sudo mv ~/${PRJ_NAME}/lib/libmysqlclient.so.18.0.0 ~/${PRJ_NAME}/lib/libmysqlclient.so.18
mkdir ~/${PRJ_NAME}/lib/external
cp ~/${PRJ_NAME}/lib/libmysqlclient.so.18 ~/${PRJ_NAME}/lib/external
sudo mv \
    ~/${PRJ_NAME}/rpy2/rinterface/_rinterface.cpython-34m.so \
    ~/${PRJ_NAME}/rpy2/rinterface/_rinterface.so


echo -e "$INFO Zipping the deployment package"
zip -qr9 ~/${LAMBDA_ZIP} *
echo -e "$INFO Finished zipping the deployment package"

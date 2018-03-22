#!/bin/bash

# run on EC2 to create deployment package

# preparing project folder, created when files were copied
echo -e "$INFO Creating deployment package"
sudo chmod -R a+w ~/${PRJ_NAME}
cd ~/${PRJ_NAME}
echo -e "$INFO PWD: $(pwd)"

# Python 3 packages transfer
echo -e "$INFO Transferring Python 3.6 packages to the deployment package"
source ~/env/bin/activate
cd ~/${PRJ_NAME}
cp -r ${CP_VERBOSE} ~/env/lib64/python3.6/site-packages/* ~/${PRJ_NAME}
deactivate

cp /usr/lib64/python3.6/lib-dynload/_sqlite3.cpython-36m-x86_64-linux-gnu.so \
    ~/${PRJ_NAME}

# Copy R needed libraries into project directory
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
echo -e "$INFO Changed permissions"

# Organizing libraries for deployment package
cp -r ${CP_VERBOSE} ~/library/* ~/${PRJ_NAME}/library
cp ~/${PRJ_NAME}/bin/exec/R ~/${PRJ_NAME}
cp /usr/lib64/libblas.so.3 ~/${PRJ_NAME}/lib
cp /usr/lib64/liblapack.so.3 ~/${PRJ_NAME}/lib

cp ~/${PRJ_NAME}/rpy2/rinterface/_rinterface.cpython-36m-x86_64-linux-gnu.so \
    ~/${PRJ_NAME}/rpy2/rinterface/_rinterface.so

mkdir ~/${PRJ_NAME}/lib/external

# uncomment the following lines in case mysql is needed
# cp /usr/lib64/mysql/libmysqlclient.so.18.0.0 \
#    ~/${PRJ_NAME}/lib/external/libmysqlclient.so.18

# Check package file size
maxsize=250
size=$(du -sm | awk '{ print $1 }')
  if [ $size -ge $maxsize ]; then
     echo -e "$ERROR File size exceeds 250MB."
     exit 1
fi

echo -e "$INFO Zipping the deployment package ..."
LAMBDA_ZIP_NAME="${LAMBDA_FUNCTION_NAME}.zip"
zip -qr9 ~/${LAMBDA_ZIP_NAME} *
echo -e "$INFO Finished zipping the deployment package to" \
    "$(FC $LAMBDA_ZIP_NAME)"

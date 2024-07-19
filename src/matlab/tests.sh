#!/usr/bin/env bash
# Calls conatins to test the install scripts

# Check default installation for r2024a
RELEASE=r2024a
RUN_INSTALL_SCRIPT="env RELEASE=${RELEASE} /mounted/src/matlab/install.sh "
# TEST="python3 -m pip list | grep matlabengine && echo PASSED! || echo FAILED!"
docker run -it --rm --entrypoint /usr/bin/sh -v `pwd`:/mounted ubuntu:20.04 -c "$RUN_INSTALL_SCRIPT && echo PASSED! || echo FAILED!"

RELEASE=r2022b
RUN_INSTALL_SCRIPT="env RELEASE=${RELEASE} /mounted/src/matlab/install.sh "
# TEST="python3 -m pip list | grep matlabengine && echo PASSED! || echo FAILED!"
docker run -it --rm --entrypoint /usr/bin/sh -v `pwd`:/mounted registry.access.redhat.com/ubi9/ubi:latest -c "$RUN_INSTALL_SCRIPT && echo PASSED! || echo FAILED!"

RELEASE=r2024a
RUN_INSTALL_SCRIPT="env RELEASE=${RELEASE} /mounted/src/matlab/install.sh "
# TEST="python3 -m pip list | grep matlabengine && echo PASSED! || echo FAILED!"
docker run -it --rm --entrypoint /usr/bin/bash -v `pwd`:/mounted registry.access.redhat.com/ubi9/ubi:latest

# RELEASE=r2024a
# RUN_INSTALL_SCRIPT="sudo env INSTALLMATLABENGINEFORPYTHON=true SKIPMATLABINSTALL=true _CONTAINER_USER=matlab \
# _CONTAINER_USER_HOME=/home/matlab DESTINATION=/opt/matlab/${RELEASE^} RELEASE=${RELEASE} \
# ~/install/install.sh "
# TEST_IF_MATLABENGINE_INSTALLED="python3 -m pip list | grep matlabengine && echo PASSED! || echo FAILED!"
# docker run -it --rm --entrypoint /bin/sh -v `pwd`/src/matlab/:/home/matlab/install mathworks/matlab:${RELEASE} -c "$RUN_INSTALL_SCRIPT && $TEST_IF_MATLABENGINE_INSTALLED"
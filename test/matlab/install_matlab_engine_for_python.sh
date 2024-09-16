#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with
# "image": "mathworks/matlab:R2024a",
# "features": {
#     "matlab": {
#         "destination": "/opt/matlab/R2024a",
#         "skipMATLABInstall": true,
#         "installMatlabEngineForPython": true
#     }
# },
# "containerUser": "matlab"

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
# OR:
# devcontainer features test -p `pwd` -f matlab --filter install_matlab_engine_for_python --log-level debug

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# check <LABEL> <cmd> [args...]

check "python3 is installed" bash -c "python3 --version"

check "matlabengine has been installed"  bash -c "python3 -m pip list | grep matlabengine"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults


#### Commands to test in container:
# RELEASE=R2024a
# RUN_INSTALL_SCRIPT="sudo env INSTALLMATLABENGINEFORPYTHON=true SKIPMATLABINSTALL=true _CONTAINER_USER=matlab \
# _CONTAINER_USER_HOME=/home/matlab DESTINATION=/opt/matlab/${RELEASE^} RELEASE=${RELEASE} \
# ~/install/install.sh "
# TEST_IF_MATLABENGINE_INSTALLED="python3 -m pip list | grep matlabengine && echo PASSED! || echo FAILED!"
# docker run -it --rm --entrypoint /bin/sh -v `pwd`/src/matlab/:/home/matlab/install mathworks/matlab:${RELEASE} -c "$RUN_INSTALL_SCRIPT && $TEST_IF_MATLABENGINE_INSTALLED"

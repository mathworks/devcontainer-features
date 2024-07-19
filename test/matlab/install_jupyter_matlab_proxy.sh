#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with:
# "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
# "features": {
#     "matlab": {
#         "installJupyterMatlabProxy": true,
#         "skipMATLABInstall": true
#     }
# }

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
# OR :
# devcontainer features test -p `pwd` -f matlab --filter install_jupyter_matlab_proxy
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# check <LABEL> <cmd> [args...]

check "python3 is installed" python3 --version

check "jupyter-matlab-proxy has been installed"  bash -c "python3 -m pip list | grep jupyter-matlab-proxy"

check "jupyter-lab is installed" bash -c "jupyter-lab --version"

check "matlab-proxy has been installed"  bash -c "python3 -m pip list | grep matlab-proxy"

check "matlab-proxy-app is callable" bash -c "matlab-proxy-app -h"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults

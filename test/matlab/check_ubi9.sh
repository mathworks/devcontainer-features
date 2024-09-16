#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with the R2024a release, and a support package installed.
# Support package installation is special, because these packages need to be installed into
# the end users HOME folder and not into the root users folders. Installing into root will
# result in users being unable to access the Support Packages.
#
# "check_ubi9": {
#         "image": "registry.access.redhat.com/ubi9/ubi:latest",
#         "features": {
#             "ghcr.io/devcontainers/features/common-utils:2": {
#                 "installZsh": false,
#                 "installOhMyZshConfig": false,
#                 "username": "vscode",
#                 "userUid": "1000",
#                 "userGid": "1000",
#                 "upgradePackages": "true"
#             },
#             "matlab": {
#                 "release": "R2024a",
#                 "products": "MATLAB MATLAB_Support_Package_for_Android_Sensors",
#                 "startInDesktop": "test"
#             }
#         },
#         "containerUser": "vscode"
#     }

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
# OR:
# devcontainer features test -p `pwd` -f matlab --filter check_ubi9  --log-level debug
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# check <LABEL> <cmd> [args...]

# Verify that the right release is installed in the expected location.
check "is ubi9 " bash -c "cat /etc/os-release | grep 'ID.*rhel' "

check "R2024a is installed" bash -c "cat /opt/matlab/R2024a/VersionInfo.xml | grep '<release>R2024a</release>'"

# Verify MATLAB_Support_Package_for_Android_Sensors is installed at the right place (ie: The home folder for the containerUser : vscode )
check "support package is installed" bash -c "cat /home/vscode/Documents/MATLAB/SupportPackages/R2024a/ssiSearchFolders | head -1 | grep 'toolbox/matlab/hardware/shared/hwsdk'"


check "python3 is installed" python3 --version

check "matlab-proxy has been installed"  bash -c "python3 -m pip list | grep matlab-proxy"

check "matlab-proxy-app is callable" bash -c "matlab-proxy-app -h"

check "is startInDesktop marker file present" bash -c "ls ~/.teststartmatlabdesktop"

check "jupyter-lab is installed" bash -c "jupyter-lab --version"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
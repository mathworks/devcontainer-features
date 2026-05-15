#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2026 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with the R2026a release on a Debian 12 base image.
# This verifies the version-aware OS mapping (debian12 directory) and architecture-aware
# dependency fetching introduced with R2026a.
#

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:debian-12 \
#                   `pwd`
# OR:
# devcontainer features test -p `pwd` -f matlab --filter check_debian12  --log-level debug
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# check <LABEL> <cmd> [args...]

check "is debian" bash -c "cat /etc/os-release | grep 'ID=debian'"

check "debian version is 12" bash -c "cat /etc/os-release | grep 'VERSION_ID=\"12\"'"

# Verify that the right release is installed in the expected location.
check "R2026a is installed" bash -c "cat /opt/matlab/R2026a/VersionInfo.xml | grep '<release>R2026a</release>'"

# Verify MATLAB_Support_Package_for_Android_Sensors is installed at the right place (ie: The home folder for the containerUser : vscode )
check "support package is installed" bash -c "cat /home/vscode/Documents/MATLAB/SupportPackages/R2026a/ssiSearchFolders | tail -1 | grep 'toolbox/matlab/hardware/supportpackages/sharedmobilesensor'"

check "NLM information is saved in bashrc" bash -c "echo $MLM_LICENSE_FILE | grep 123@abc.com"

check "python3 is installed" bash -c "python3 --version"

check "matlab-proxy has been installed" bash -c "python3 -m pip list | grep matlab-proxy"

check "matlab-proxy-app is callable" bash -c "matlab-proxy-app -v"

check "jupyter lab is installed" bash -c "jupyter lab --version"

check "MATLAB Engine for python is installed" bash -c "python3 -m pip list | grep -i 'matlabengine'"

check "MathWorks Telemetry is enabled in bashrc" bash -c 'echo $MW_CONTEXT_TAGS | grep DEVCONTAINER_FEATURE'

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults

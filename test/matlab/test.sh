#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'matlab' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "matlab": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in
# the Feature's 'devcontainer-feature.json'.
# For the 'matlab' feature, that means the default version installed in r2024a
# These are the default values that are passed into the feature:
#     RELEASE="r2024a"
#     OS="ubuntu22.04"
#     PRODUCTS="MATLAB"
#     DOC="false"
#     INSTALLGPU="false"
#     DESTINATION="/opt/matlab"
#     INSTALLMATLABPROXY="false"
#     INSTALLJUPYTERMATLABPROXY="false"
#     INSTALLMATLABENGINEFORPYTHON="false"
#     STARTINDESKTOP="false"
#     NETWORKLICENSEMANAGER=""
#     SKIPMATLABINSTALL="false"
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.
#
# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
#
set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "r2024a is installed" bash -c "cat /opt/matlab/r2024a/VersionInfo.xml | grep '<release>R2023b</release>'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
#!/bin/bash
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "r2022b is installed" bash -c "cat /opt/matlab/R2022b/VersionInfo.xml | grep '<release>R2022b</release>'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
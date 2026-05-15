#!/usr/bin/env bash
# This script install the OS dependencies required by MATLAB for the release specified in the
# environment variable MATLAB_RELEASE on any linux OS that is dervied from Ubuntu or RHEL
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024-2026 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------

set -eu -o pipefail
# exits on an error (-e, equivalent to -o errexit);
# exits on an undefined variable (-u, equivalent to -o nounset);
# exits on an error in piped-together commands (-o pipefail)

# Uncomment to debug:
# set -x
# Or, set environment variable "SHELLOPTS=xtrace" before starting script

if [ $(basename "$0") != "install-matlab-deps.sh" ]; then
    _SCRIPT_LOCATION="$1"
    source ${_SCRIPT_LOCATION}/install-helper-functions.sh
else
    source $(dirname "$0")/install-helper-functions.sh
fi


# Verify if valid MATLAB_RELEASE
if [ "$(ihf_is_valid_matlab_release)" == "false" ]; then
    ihf_print_and_exit "Invalid or Unsupported MATLAB_RELEASE: $MATLAB_RELEASE "
fi

function print_os_info(){
    . /etc/os-release
    echo "Running install-matlab-deps script on: $PRETTY_NAME"
    echo "ID=$ID , VERSION_ID=$VERSION_ID, for MATLAB_RELEASE=$MATLAB_RELEASE"
}

function get_prerequisite_pkgs() {
    # Returns the list of pre-requisite packages required to install matlab-deps
    local PKGS="wget unzip ca-certificates"
    # mpm v2026.3 onwards requires libatomic
    if [ "$(ihf_is_debian_or_rhel)" == "rhel" ]; then
        PKGS="${PKGS} libatomic"
    else
        PKGS="${PKGS} libatomic1"
    fi
    echo "$PKGS"
}

function get_base_dependencies_list() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    local BASE_URL="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE,}/${MATLAB_DEPS_OS_VERSION}"
    local PKGS=""

    # First try to fetch dependency file based on arch.
    # If the dependency file for the specific arch version is not present then fallback to using the default dependency file.
    local ARCH=$(ihf_is_amd64_or_arm64)
    if [ "${ARCH}" != "unknown" ]; then
        local ARCH_DEPS_URL="${BASE_URL}/base-dependencies-${ARCH}.txt"
        PKGS=$(wget -qO- "${ARCH_DEPS_URL}" 2>/dev/null || true)
    fi
    if [ -z "${PKGS}" ]; then
        local GENERIC_DEPS_URL="${BASE_URL}/base-dependencies.txt"
        PKGS=$(wget -qO- "${GENERIC_DEPS_URL}" 2>/dev/null || true)
    fi

    if ihf_is_matlab_release_older_than R2026a && ihf_is_debian_13; then
        PKGS=$(echo $PKGS | tr ' ' '\n' | grep -v 'dpdk' | tr '\n' ' ')
    fi

    if [ -z "${PKGS}" ]; then
        ihf_print_and_exit "${MATLAB_DEPS_OS_VERSION} is not a supported OS for MATLAB ${MATLAB_RELEASE} ."
    fi
    echo $PKGS
}

function install_matlab_deps() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    
    print_os_info
    
    local PREREQ_PACKAGES=$(get_prerequisite_pkgs)
    
    ihf_install_packages "$PREREQ_PACKAGES"
    
    echo "Get list of dependencies for ${MATLAB_RELEASE} on ${MATLAB_DEPS_OS_VERSION}"
    local BASE_DEPS_PKGS=$(get_base_dependencies_list)
    ihf_install_packages "$BASE_DEPS_PKGS"
    
    ihf_clean_up
    # Return 0 to indicate success!
    return 0
}
install_matlab_deps


#!/usr/bin/env bash
# This script install the OS dependencies required by MATLAB for the release specified in the
# environment variable MATLAB_RELEASE on any linux OS that is dervied from Ubuntu or RHEL
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
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
    echo "wget unzip ca-certificates"
}

function get_base_dependencies_list() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    local BASE_DEPS_URL=https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE,}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt
    # Get matlab_deps - if this fails, then we aren't on a supported os
    local PKGS=$(wget -qO- ${BASE_DEPS_URL})
    if [ -z "$PKGS" ]; then
        ihf_print_and_exit "${MATLAB_DEPS_OS_VERSION} is not a supported OS for MATLAB ${MATLAB_RELEASE} ."
    fi
    echo $PKGS
}

function install_matlab_deps() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    # local linux_distro=$(ihf_is_debian_or_rhel)
    
    print_os_info
    
    local PREREQ_PACKAGES=$(get_prerequisite_pkgs)
    
    ihf_install_packages "$PREREQ_PACKAGES"
    
    echo "Get list of dependencies from ${MATLAB_RELEASE}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt"
    local BASE_DEPS_PKGS=$(get_base_dependencies_list)
    ihf_install_packages "$BASE_DEPS_PKGS"
    
    ihf_clean_up
    # Return 0 to indicate success!
    return 0
}
install_matlab_deps


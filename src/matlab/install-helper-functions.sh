#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
# Helpers functions to encapsulate OS specific installation

set -eu -o pipefail

# Global variable to store the last error message.
LAST_ERR=""

function _ihf_print_installation_status_on_exit() {
    if [ $? -eq 0 ]; then
        printf "Done!\n"
    else
        printf "$LAST_ERR \nFailed to install for MATLAB ${MATLAB_RELEASE:-undefined} on ${PRETTY_NAME:-undefined}.\nTo debug, call script with SHELLOPTS=xtrace \n"
    fi
}

trap _ihf_print_installation_status_on_exit EXIT

function ihf_print_and_exit() {
    LAST_ERR="$1"
    printf "$LAST_ERR, exiting...\n"
    exit 1
}

function ihf_get_matlab_deps_os() {
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    local MATLAB_DEPS_OS_VERSION="undefined"
    # get os-release variables
    . /etc/os-release
    
    case ${LINUX_DISTRO} in
        debian)
            if [[ "${ID}" == "ubuntu" ]]; then
                local SUPPORTED_VERSION_CODENAME="focal jammy"
                MATLAB_DEPS_OS_VERSION=${ID}${VERSION_ID}
                elif [[ "${ID}" == "debian" ]]; then
                local SUPPORTED_VERSION_CODENAME="bullseye bookworm"
                local UBUNTU_VERSION_ID=${VERSION_ID/11/20.04}
                UBUNTU_VERSION_ID=${UBUNTU_VERSION_ID/12/22.04}
                MATLAB_DEPS_OS_VERSION=ubuntu${UBUNTU_VERSION_ID}
            fi
        ;;
        rhel)
            if [[ "${ID}" == "rhel" ]]; then
                # This link lists the Fedora base image that a particular RHEL version depends on:
                # https://docs.fedoraproject.org/en-US/quick-docs/fedora-and-red-hat-enterprise-linux/
                # UBI 9 -> Fedora 34
                # UBI 8 -> Fedora 28
                # The End of life for these distributions can be found here:
                # https://endoflife.date/rhel
                # https://endoflife.date/fedora
                local SUPPORTED_MAJOR_VERSION="8 9"
                local MATLAB_DEPS_OS_VERSION="ubi"
                local MAJOR_VERSION_ID=$(echo $VERSION_ID | cut -d '.' -f 1)
                local MAJOR_VERSION_ID_REGEX="\<${MAJOR_VERSION_ID}\>"
                if [[ ${SUPPORTED_MAJOR_VERSION[@]} =~ ${MAJOR_VERSION_ID_REGEX} ]]; then
                    MATLAB_DEPS_OS_VERSION=${MATLAB_DEPS_OS_VERSION}${MAJOR_VERSION_ID}
                else
                    ihf_print_and_exit "Un-supported version ${MAJOR_VERSION_ID}"
                fi
                
                elif [[ "${ID}" == "fedora" ]]; then
                # Assuming UBI 9 as fedora 28 was at end of life in 2018.
                MATLAB_DEPS_OS_VERSION="ubi9"
            else
                ihf_print_and_exit "Unsupported OS ${ID}"
            fi
        ;;
    esac
    
    #return value
    echo $MATLAB_DEPS_OS_VERSION
    
}

function _ihf_get_additional_repos (){
    . /etc/os-release
    
    local _DISTRO=$(ihf_is_debian_or_rhel)
    # To find some devel packages, some rhel need to enable specific extra repos, but not on RedHat ubi images...
    local INSTALL_CMD_ADDL_REPOS=""
    if [ ${_DISTRO} = "rhel" ] && [ ${ID} != "rhel" ]; then
        local MAJOR_VERSION_ID=$(echo $VERSION_ID | cut -d '.' -f 1)
        if [ ${MAJOR_VERSION_ID} = "8" ]; then
            INSTALL_CMD_ADDL_REPOS="--enablerepo powertools"
            elif [ ${MAJOR_VERSION_ID} = "9" ]; then
            INSTALL_CMD_ADDL_REPOS="--enablerepo crb"
        fi
    fi
    
    echo $INSTALL_CMD_ADDL_REPOS
}


function ihf_get_pkg_mgr_cmd() {
    local PKG_MGR_CMD=""
    if type apt-get >/dev/null 2>&1; then
        PKG_MGR_CMD=apt-get
        elif type microdnf >/dev/null 2>&1; then
        PKG_MGR_CMD=microdnf
        elif type dnf >/dev/null 2>&1; then
        PKG_MGR_CMD=dnf
    else
        PKG_MGR_CMD=yum
    fi
    
    echo $PKG_MGR_CMD
}

function ihf_get_install_cmd() {
    local PKG_MGR_CMD=$(ihf_get_pkg_mgr_cmd)
    local INSTALL_CMD=""
    if type apt-get >/dev/null 2>&1; then
        INSTALL_CMD="${PKG_MGR_CMD} -y install --no-install-recommends"
        elif type microdnf >/dev/null 2>&1; then
        INSTALL_CMD="${PKG_MGR_CMD} $(_ihf_get_additional_repos) -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
        elif type dnf >/dev/null 2>&1; then
        INSTALL_CMD="${PKG_MGR_CMD} $(_ihf_get_additional_repos) -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
    else
        INSTALL_CMD="${PKG_MGR_CMD} $(_ihf_get_additional_repos) -y install --disableplugin=subscription-manager --noplugins --setopt=install_weak_deps=0"
    fi
    
    echo $INSTALL_CMD
}

function ihf_get_remove_cmd() {
    local PKG_MGR_CMD=$(ihf_get_pkg_mgr_cmd)
    local REMOVE_CMD="${PKG_MGR_CMD} -y remove"
    
    echo $REMOVE_CMD
}

# returns "true/false" string if MATLAB_RELEASE is valid
function ihf_is_valid_matlab_release() {
    # List of supported MATLAB_RELEASE values
    local _SUPPORTED_MATLAB_RELEASES=("r2024a" "r2023b" "r2023a" "r2022b" "r2022a" "r2021b" "r2021a" "r2020b" "r2020a" "r2019b" "r2019a")
    
    ## Validate MATLAB_RELEASE
    if [ -z "$MATLAB_RELEASE" ]; then
        echo "false"
    else
        # checking if valid matlab release configuration
        local _RELEASE_REGEX="\<${MATLAB_RELEASE}\>"
        if [[ ${_SUPPORTED_MATLAB_RELEASES[@]} =~ ${_RELEASE_REGEX} ]]; then
            echo "true"
        else
            echo "false"
        fi
    fi
}

function ihf_is_debian_or_rhel() {
    . /etc/os-release
    
    if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
        echo "debian"
        elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
        echo "rhel"
    else
        ihf_print_and_exit "Linux distro ${ID} not supported."
    fi
}

function ihf_clean_up() {
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    case ${LINUX_DISTRO} in
        debian)
            rm -rf /var/lib/apt/lists/*
            apt-get clean && apt-get autoremove
        ;;
        rhel)
            rm -rf /var/cache/dnf/* /var/cache/yum/*
            rm -rf /tmp/yum.log
            yum --disableplugin=subscription-manager clean all -y
        ;;
    esac
}

ihf_updaterc() {
    local _bashrc
    local _zshrc
    if [ "${UPDATE_RC}" = "true" ]; then
        case $ADJUSTED_ID in
            debian)
                echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
                _bashrc=/etc/bash.bashrc
                _zshrc=/etc/zsh/zshrc
            ;;
            rhel)
                echo "Updating /etc/bashrc and /etc/zshrc..."
                _bashrc=/etc/bashrc
                _zshrc=/etc/zshrc
            ;;
        esac
        if [[ "$(cat ${_bashrc})" != *"$1"* ]]; then
            echo -e "$1" >>${_bashrc}
        fi
        if [ -f "${_zshrc}" ] && [[ "$(cat ${_zshrc})" != *"$1"* ]]; then
            echo -e "$1" >>${_zshrc}
        fi
    fi
}

function ihf_pkg_mgr_update() {
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    local PKG_MGR_CMD=$(ihf_get_pkg_mgr_cmd)
    echo "UPDATING using $PKG_MGR_CMD"
    case $LINUX_DISTRO in
        debian)
            echo "Running apt-get update..."
            ${PKG_MGR_CMD} update -y
        ;;
        rhel)
            if [ ${PKG_MGR_CMD} = "microdnf" ]; then
                if [ "$(ls /var/cache/yum/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} makecache ..."
                    ${PKG_MGR_CMD} makecache
                fi
            else
                if [ "$(ls /var/cache/${PKG_MGR_CMD}/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} check-update ..."
                    set +e
                    ${PKG_MGR_CMD} check-update
                    rc=$?
                    if [ $rc != 0 ] && [ $rc != 100 ]; then
                        exit 1
                    fi
                    set -e
                fi
            fi
        ;;
    esac
}

# Checks if packages are installed and installs them if not
function ihf_install_packages() {
    
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    local INSTALL_CMD=$(ihf_get_install_cmd)
    echo "install command: $INSTALL_CMD"
    echo "INSTALLING $@"
    case ${LINUX_DISTRO} in
        debian)
            if ! dpkg -s "$@" >/dev/null 2>&1; then
                ihf_pkg_mgr_update && \
                ${INSTALL_CMD} $@
            fi
        ;;
        rhel)
            if ! rpm -q "$@" >/dev/null 2>&1; then
                ihf_pkg_mgr_update
                ${INSTALL_CMD} $@
            fi
        ;;
    esac
}

function ihf_remove_packages() {
    
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    local REMOVE_CMD=$(ihf_get_remove_cmd)
    echo "remove command: $REMOVE_CMD"
    echo "REMOVING: $@"
    case ${LINUX_DISTRO} in
        debian)
            if dpkg -s "$@" >/dev/null 2>&1; then
                ${REMOVE_CMD} $@
            fi
        ;;
        rhel)
            if rpm -q "$@" >/dev/null 2>&1; then
                ${REMOVE_CMD} $@
            fi
        ;;
    esac
}

function test_script() {
    # Only run tests if this script is called directly
    # These will not run if this script is sourced from another file
    if [ $(basename "$0") == "install-helper-functions.sh" ]; then
        echo "=============Starting test"
        echo "me=$(basename "$0")"
        
        echo "testing update"
        ihf_pkg_mgr_update
        
        
        MATLAB_RELEASE=r2024a
        is_release_valid=$(ihf_is_valid_matlab_release)
        echo "Is $MATLAB_RELEASE valid? Ans: $is_release_valid"
        
        MATLAB_RELEASE=r2023bd
        echo "Is $MATLAB_RELEASE valid? Ans: $(ihf_is_valid_matlab_release)"
        
        LINUX_DISTRO=$(ihf_is_debian_or_rhel)
        echo "LINUX_DISTRO: $LINUX_DISTRO"
        
        matlab_deps_os=$(ihf_get_matlab_deps_os)
        echo "The MATLAB deps to install is: $matlab_deps_os"
        
        install_cmd=$(ihf_get_install_cmd)
        echo "install_cmd: $install_cmd"
        
        echo "Finished test=============="
    fi
}

test_script

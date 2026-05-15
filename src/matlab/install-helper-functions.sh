#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024-2026 The MathWorks, Inc.
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

# Get the os for fetching matlab-deps, for MATLAB R2025b or older debian uses ubuntu dependencies
function ihf_get_matlab_deps_os() {
    local LINUX_DISTRO=$(ihf_is_debian_or_rhel)
    local MATLAB_DEPS_OS_VERSION="undefined"
    # get os-release variables
    . /etc/os-release
    
    case ${LINUX_DISTRO} in
        debian)
            if [[ "${ID}" == "ubuntu" ]]; then
                MATLAB_DEPS_OS_VERSION=${ID}${VERSION_ID}
            elif [[ "${ID}" == "debian" ]]; then
            # from MATLAB R2026a ubuntu and debian have separate set of dependencies.
                if ! ihf_is_matlab_release_older_than R2026a && [[ "${VERSION_ID}" -ge 12 ]]; then
                    MATLAB_DEPS_OS_VERSION="debian${VERSION_ID}"
                else
                    local UBUNTU_VERSION_ID=${VERSION_ID/11/20.04}
                    UBUNTU_VERSION_ID=${UBUNTU_VERSION_ID/12/22.04}
                    UBUNTU_VERSION_ID=${UBUNTU_VERSION_ID/13/24.04}
                    MATLAB_DEPS_OS_VERSION=ubuntu${UBUNTU_VERSION_ID}
                fi
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
    local _SUPPORTED_MATLAB_RELEASES=("R2026a" "R2025b" "R2025a" "R2024b" "R2024a" "R2023b" "R2023a" "R2022b" "R2022a" "R2021b" "R2021a" "R2020b" "R2020a" "R2019b" "R2019a")
    
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

# Checks if MATLAB Version in environment variable MATLAB_RELEASE is older the MATLAB Version passed in parameters, 
# Version should be of the format R<YEAR>a|b
function ihf_is_matlab_release_older_than() {
    # ',' converts the MATLAB_RELEASE and the value passed (target) to lower case.
    local source="${MATLAB_RELEASE,,}"
    local target="${1,,}"

    local release_pattern='^r[0-9]{4}[ab]$'
    if [[ ! "${source}" =~ ${release_pattern} ]]; then
        ihf_print_and_exit "Invalid MATLAB_RELEASE format: '${MATLAB_RELEASE}'. Expected format: R<year><a|b> (e.g., R2026a)"
    fi
    if [[ ! "${target}" =~ ${release_pattern} ]]; then
        ihf_print_and_exit "Invalid target release format: '${1}'. Expected format: R<year><a|b> (e.g., R2026a)"
    fi

    local source_year="${source:1:4}"
    local target_year="${target:1:4}"
    local source_suffix="${source:5:1}"
    local target_suffix="${target:5:1}"

    if [ "${source_year}" -lt "${target_year}" ]; then
        return 0
    elif [ "${source_year}" -gt "${target_year}" ]; then
        return 1
    fi

    if [[ "${source_suffix}" < "${target_suffix}" ]]; then
        return 0
    else
        return 1
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


function ihf_is_debian_13 {
    . /etc/os-release
    if [ "${ID}" = "debian" ] && [ "${VERSION_ID}" = "13" ]; then
        # True
        return 0
    else
        # False
        return 1
    fi
}

# Gets arch and returns amd64, arm64 in all other cases returns unknown 
function ihf_is_amd64_or_arm64() {
    local machine
    machine=$(uname -m)
    case "${machine}" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
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


        MATLAB_RELEASE=R2024a
        is_release_valid=$(ihf_is_valid_matlab_release)
        echo "Is $MATLAB_RELEASE valid? Ans: $is_release_valid"

        MATLAB_RELEASE=R2023bd
        echo "Is $MATLAB_RELEASE valid? Ans: $(ihf_is_valid_matlab_release)"

        LINUX_DISTRO=$(ihf_is_debian_or_rhel)
        echo "LINUX_DISTRO: $LINUX_DISTRO"

        matlab_deps_os=$(ihf_get_matlab_deps_os)
        echo "The MATLAB deps to install is: $matlab_deps_os"

        install_cmd=$(ihf_get_install_cmd)
        echo "install_cmd: $install_cmd"

        arch=$(ihf_is_amd64_or_arm64)
        echo "Architecture: $arch"

        echo "--- Testing ihf_is_matlab_release_older_than ---"

        MATLAB_RELEASE=R2026a
        if ihf_is_matlab_release_older_than R2026a; then
            echo "FAIL: R2026a should NOT be older than R2026a"
        else
            echo "PASS: R2026a is not older than R2026a"
        fi

        MATLAB_RELEASE=R2025b
        if ihf_is_matlab_release_older_than R2026a; then
            echo "PASS: R2025b is older than R2026a"
        else
            echo "FAIL: R2025b should be older than R2026a"
        fi

        MATLAB_RELEASE=R2027a
        if ihf_is_matlab_release_older_than R2026a; then
            echo "FAIL: R2027a should NOT be older than R2026a"
        else
            echo "PASS: R2027a is not older than R2026a"
        fi

        MATLAB_RELEASE=R2026a
        if ihf_is_matlab_release_older_than R2026b; then
            echo "PASS: R2026a is older than R2026b"
        else
            echo "FAIL: R2026a should be older than R2026b"
        fi

        MATLAB_RELEASE=R2026b
        if ihf_is_matlab_release_older_than R2026a; then
            echo "FAIL: R2026b should NOT be older than R2026a"
        else
            echo "PASS: R2026b is not older than R2026a"
        fi

        MATLAB_RELEASE=R2026b
        if ihf_is_matlab_release_older_than R2026b; then
            echo "FAIL: R2026b should NOT be older than R2026b"
        else
            echo "PASS: R2026b is not older than R2026b"
        fi

        MATLAB_RELEASE=R2025a
        if ihf_is_matlab_release_older_than r2026A; then
            echo "PASS: R2025a is older than r2026A (case insensitive)"
        else
            echo "FAIL: R2025a should be older than r2026A (case insensitive)"
        fi

        echo "--- Testing ihf_is_matlab_release_older_than with invalid formats ---"

        MATLAB_RELEASE=R2026
        if msg=$(ihf_is_matlab_release_older_than R2026a 2>&1); then
            echo "FAIL: R2026 (no suffix) should be rejected"
        else
            echo "PASS: R2026 (no suffix) rejected: $msg"
        fi

        MATLAB_RELEASE=R2026a
        if msg=$(ihf_is_matlab_release_older_than R2026 2>&1); then
            echo "FAIL: target R2026 (no suffix) should be rejected"
        else
            echo "PASS: target R2026 (no suffix) rejected: $msg"
        fi

        MATLAB_RELEASE=2026a
        if msg=$(ihf_is_matlab_release_older_than R2026a 2>&1); then
            echo "FAIL: 2026a (no R prefix) should be rejected"
        else
            echo "PASS: 2026a (no R prefix) rejected: $msg"
        fi

        MATLAB_RELEASE=R2026c
        if msg=$(ihf_is_matlab_release_older_than R2026a 2>&1); then
            echo "FAIL: R2026c (invalid suffix) should be rejected"
        else
            echo "PASS: R2026c (invalid suffix) rejected: $msg"
        fi

        echo "Finished test=============="
    fi
}

test_script

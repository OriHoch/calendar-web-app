# functions which may run on a host machine with partial dependencies
#
# used to bootstrap the full environment which runs inside a docker container
#
# should make an effort to be as compatible as possible


preflight_check() {
    # simple wrapper for checking a condition and attempt to install missing dependencies interactively
    local CHECK="${1}"
    local ERROR="${2}"
    local INSTALL="${3}"
    if ! eval "${CHECK}" >/dev/null 2>&1; then
        error "${ERROR}"
        if [ "${UPV_INTERACTIVE}" == "1" ]; then
            read -p "Try to install? [Y/n] "
            if [ "${REPLY}" == "n" ]; then
                return 1
            else
                eval "${INSTALL}"
            fi
        else
            info "Run in interactive mode (UPV_INTERACTIVE=0) to let the script try installing dependencies for you"
            return 1
        fi
    else
        return 0
    fi
}

upv_sh_preflight() {
    # check host environment for the minimal upv bootstrapping dependencies
    preflight_check "which python2.7" "Python 2.7 is required" "sudo apt-get install python2.7" &&\
    preflight_check "which docker" "Docker is required" "
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
        sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\";
        sudo apt-get update;
        sudo apt-get -y install docker-ce;
    " &&\
    preflight_check "which dotenv" "System Python package dotenv is required" "sudo pip install --upgrade pip setuptools && sudo pip install python-dotenv" &&\
    preflight_check "pip freeze | grep PyYAML" "System Python pip package pyyaml is required" "sudo pip install --upgrade pip setuptools && sudo pip install pyyaml" &&\
    preflight_check "which jq" "Jq is required" "sudo apt-get install jq" &&\
    preflight_check "which uuidgen" "uuid-runtime is required" "sudo apt-get install uuid-runtime"
}

upv_sh_handle_pull() {
    # handles the functionality for ./upv.sh --pull
    # return 0 = handled pull successfully, 1 = failed to handle pull, 2 = no need to handle pull
    # this is used to speed up builds later using --cache-from
    if [ "${1}" == "--pull" ] || [ "${2}" == "--pull" ]; then
        # look for pull-tag attribute inside upv.yaml files recursively in all sub-directories
        for UPV_YAML_FILE in `find . -iname upv.yaml`; do
            UPV_MODULE_DIR=`dirname $UPV_YAML_FILE`
            UPV_MODULE_DIR="${UPV_MODULE_DIR//\.\//}"
            debug `dumpenv UPV_YAML_FILE UPV_MODULE_DIR`
            PULL_TAG=`yaml_get "${UPV_YAML_FILE}" "pull-tag"`
            if [ "${PULL_TAG}" != "" ]; then
                if docker pull "${PULL_TAG}"; then
                    dotenv_set "${UPV_MODULE_DIR}/.env" "PULLED_TAG" "${PULL_TAG}"
                    dotenv_set "${UPV_MODULE_DIR}/.env" "PULLED_TAG_DATE" `date +%F`
                else
                    dotenv_set "${UPV_MODULE_DIR}/.env" "PULLED_TAG" ""
                    dotenv_set "${UPV_MODULE_DIR}/.env" "PULLED_TAG_DATE" ""
                    # will fail only if UPV_STRICT=1
                    strict_warning "Pull failed to module-dir: ${UPV_MODULE_DIR}, pull-tag: ${PULL_TAG}" && return 1
                fi
            fi
        done
        return 0
    else
        return 2
    fi
}

upv_sh_handle_push() {
    # handles the functionality for ./upv.sh --push
    # return 0 = handled successfully, 1 = failed, 2 = skipped
    if [ "${1}" == "--push" ] || [ "${2}" == "--push" ]; then
        info "Building root upv image"
        local ROOT_UPV_TAG=`upv_build_root_docker_image`; [ "${ROOT_UPV_TAG}" == "" ] && return 1
        info `dumpenv ROOT_UPV_TAG`
        info "Building base upv image"
        local BASE_UPV_TAG=`upv_build_base_docker_image "${ROOT_UPV_TAG}"`; [ "${BASE_UPV_TAG}" == "" ] && return 1
        info `dumpenv BASE_UPV_TAG`
        for UPV_YAML_FILE in `find . -iname upv.yaml`; do
            UPV_MODULE_DIR=`dirname $UPV_YAML_FILE`
            UPV_MODULE_DIR="${UPV_MODULE_DIR//\.\//}"
            info "Building upv module ${UPV_MODULE_DIR}"
            PULL_TAG=`yaml_get "${UPV_YAML_FILE}" "pull-tag"`
            if [ "${PULL_TAG}" != "" ]; then
                info `dumpenv PULL_TAG`
                local MODULE_TAG=`upv_build_module_docker_image "${ROOT_UPV_TAG}" "${BASE_UPV_TAG}" "${UPV_MODULE_DIR}"`
                info `dumpenv MODULE_TAG`
                [ "${MODULE_TAG}" == "" ] && error "Failed to build image" && return 1
                ! docker tag "${MODULE_TAG}" "${PULL_TAG}" && error "Failed docker tag" && return 1
                ! docker push "${PULL_TAG}" && error "Failed docker push" && return 1
            fi
        done
        return 0
    else
        return 2
    fi
}

upv_sh_handle_help() {
    # return 0 = handled help successfully, 1 = failed to handle help, 2 = no need to handle help
    if ! require_params UPV_MODULE_PATH; then
        upv_sh_help
        return 0
    else
        return 2
    fi
}

upv_sh_help() {
    # default usage message when no params are passed
    echo "Usage: ${0} [--debug] <UPV_MODULE_PATH> [CMD] [PARAMS]"
    echo "* For initial installation, run: ${0} --pull"
    return 0
}

upv_sh_read_params() {
    # parse upv.sh arguments and export as environment variables
    if [ "${1}" == "--debug" ]; then
        export UPV_DEBUG=1
    else
        export UPV_DEBUG=0
    fi
    export UPV_INTERACTIVE="${UPV_INTERACTIVE:-1}"
    export UPV_STRICT="${UPV_STRICT:-0}"
    if [ "${1}" == "--debug" ]; then
        export UPV_MODULE_PATH="${2}"
        export CMD="${3}"
        export PARAMS="${4}"
        [ "${5}" != "" ] && error "Additional params are not allowed" && return 1
    else
        export UPV_MODULE_PATH="${1}"
        export CMD="${2}"
        export PARAMS="${3}"
        [ "${4}" != "" ] && error "Additional params are not allowed" && return 1
    fi
    return 0
}

upv_sh_restore_permissions() {
    debug "Restoring file owner and group to ${USER}:${GROUP}"
    if [ "${UPV_INTERACTIVE}" == "1" ]; then
        if sudo -n true; then
            sudo chown -R $USER:$GROUP `pwd`
        else
            info "Sudo password is required to set ownership on files created inside the docker container"
            sudo chown -R $USER:$GROUP `pwd`
        fi
    else
        ! sudo -n chown -R $USER:$GROUP `pwd` &&\
            warning "Failed to set ownership on files, some files might only be accessible using root"
    fi
}

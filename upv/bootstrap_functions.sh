
preflight_check() {
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
            info "Run ./upv.sh --interactive to let the script try installing dependencies for you"
            return 1
        fi
    else
        return 0
    fi
}

upv_sh_preflight() {
    preflight_check "which python2.7" "Python 2.7 is required" "sudo apt-get install python2.7" &&\
    preflight_check "which docker" "Docker is required" "
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
        sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\";
        sudo apt-get update;
        sudo apt-get -y install docker-ce;
    "
}

upv_sh_handle_pull() {
    if [ "${1}" == "--pull" ] || [ "${2}" == "--pull" ]; then
        if [ "${1}" == "--interactive" ] || [ "${2}" == "--interactive" ]; then
            export UPV_INTERACTIVE=1
        else
            export UPV_INTERACTIVE=0
        fi
        upv_pull
        ! upv_sh_preflight && error "Failed preflight checks"
        return 0
    else
        return 1
    fi
}

upv_sh_help() {
    echo "Usage: ${0} [--debug] [--interactive] <UPV_MODULE_PATH> [CMD] [PARAMS]"
    echo "* For initial installation, run: ${0} --pull --interactive"
    return 0
}

upv_sh_read_params() {
    if [ "${1}" == "--debug" ] || [ "${2}" == "--debug" ]; then
        export UPV_DEBUG=1
    else
        export UPV_DEBUG=0
    fi

    if [ "${1}" == "--interactive" ] || [ "${2}" == "--interactive" ]; then
        export UPV_INTERACTIVE=1
    else
        export UPV_INTERACTIVE=0
    fi

    if [ "${2}" == "--interactive" ] || [ "${2}" == "--debug" ]; then
        export UPV_MODULE_PATH="${3}"
        export CMD="${4}"
        export PARAMS="${5}"
        [ "${6}" != "" ] && error "Additional params are not allowed" && return 1
    elif [ "${1}" == "--interactive" ] || [ "${1}" == "--debug" ]; then
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

docker_build_upv() {
    local UPV_DOCKER_PATH="${1}"
    local UPV_DOCKER_FILE="${2:-Dockerfile}"
    local UPV_DOCKER_TAG="${3:-upv-`uuidgen`}"
    local CMD="docker build -t ${UPV_DOCKER_TAG} -f ${UPV_DOCKER_FILE} ${UPV_DOCKER_PATH}"
    BUILD_LOG_FILE=`mktemp`
    debug `dumpenv BUILD_LOG_FILE CMD` >/dev/stderr
    $CMD > "${BUILD_LOG_FILE}" &
    PID="$!"
    local I="0"
    local TAIL_PID=""
    while ps -p "${PID}" >/dev/null; do
        printf "." >/dev/stderr
        sleep 1
        local I=`expr $I + 1`
        if [ "${I}" == "5" ]; then
            echo >/dev/stderr
            echo >/dev/stderr
            info "Sorry it's taking too long, please be patient.. It will be lightlining fast on the next run!" >/dev/stderr
            info "Tailing the build log" >/dev/stderr
            tail -f "${BUILD_LOG_FILE}" >/dev/stderr &
            echo >/dev/stderr
            TAIL_PID="$!"
        fi
    done
    if [ "${TAIL_PID}" != "" ]; then
        kill -9 $TAIL_PID
    fi
    echo >/dev/stderr
    echo "${UPV_DOCKER_TAG}"
    return 0
}

upv_sh_start() {
    printf "INFO: Starting upv"
    [ "${UPV_DEBUG}" == "1" ] && echo
    local UPV_DOCKER_PATH="${1}"
    local UPV_DOCKER_FILE="${2:-Dockerfile}"
    local UPV_DOCKER_TAG="${3}"
    DOCKER_TAG=`docker_build_upv "${UPV_DOCKER_PATH}" "${UPV_DOCKER_FILE}" "${UPV_DOCKER_TAG}"`
    [ "${DOCKER_TAG}" == "" ] &&\
        error "Failed to build upv docker image" && return 1
    debug "pwd=`pwd`"
    debug `dumpenv UPV_MODULE_PATH CMD PARAMS UPV_DEBUG UPV_INTERACTIVE`
    debug "Running upv image ${DOCKER_TAG}"
    debug "docker run -it --rm --network host \
               -v \"${UPV_HOST_WORKSPACE:-`pwd`}:/upv/workspace\" \
               -v \"/var/run/docker.sock:/var/run/docker.sock\" \
               -v \"${HOME}/.docker:/root/.docker\" \
               -e \"UPV_DEBUG=${UPV_DEBUG}\" \
               -e \"UPV_INTERACTIVE=${UPV_INTERACTIVE}\" \
               -e \"UPV_WORKSPACE=/upv/workspace\" \
               -e \"UPV_HOST_WORKSPACE=${UPV_HOST_WORKSPACE:-`pwd`}\" \
               -e \"UPV_ROOT=/upv\" \
               \"${DOCKER_TAG}\" \"${UPV_MODULE_PATH}\" \"${CMD}\" \"${PARAMS}\""
    docker run -it --rm --network host \
               -v "${UPV_HOST_WORKSPACE:-`pwd`}:/upv/workspace" \
               -v "/var/run/docker.sock:/var/run/docker.sock" \
               -v "${HOME}/.docker:/root/.docker" \
               -e "UPV_DEBUG=${UPV_DEBUG}" \
               -e "UPV_INTERACTIVE=${UPV_INTERACTIVE}" \
               -e "UPV_WORKSPACE=/upv/workspace" \
               -e "UPV_HOST_WORKSPACE=${UPV_HOST_WORKSPACE:-`pwd`}" \
               -e "UPV_ROOT=/upv" \
               "${DOCKER_TAG}" "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
    RES=$?
    if [ "${RES}" != "0" ]; then
        echo "Upv exited with error code ${RES}"
    else
        debug "Upv exited with successful return code ${RES}"
    fi
    debug "Removing image"
    docker rmi --no-prune "${DOCKER_TAG}" >/dev/null 2>&1
    debug "Restoring file owner and group to ${USER}:${GROUP}"
    sudo chown -R $USER:$GROUP `pwd`
    return 0
}

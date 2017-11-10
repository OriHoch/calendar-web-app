
## logging / UX / debugging functions

error() { echo "ERROR: ${*}"; }
warning() { echo "WARNING: ${*}"; }
info() { echo "INFO: ${*}"; }
debug() { [ "${UPV_DEBUG}" == "0" ] || echo "DEBUG: ${*}"; }

success() { echo "Great Success"; echo; echo_trim "${1}"; }

strict_warning() {
    if [ "${UPV_STRICT}" == "1" ]; then
        error "${*}"
        return 0
    else
        warning "${*}"
        return 1
    fi
}

echo_trim() {
    # echo a string while trimming whitespaces
    echo "${*}" | (
        while read -r line; do
            if [ "${line}" != "" ]; then
                echo $line
            fi
        done
    )
}

dumpenv() {
    # gets list of param names - prints their values"
    # be sure to use dumpenv_secret for secret values!"
    printf " -- "
    for PARAM in "$@"; do
        DOLLARPARAM='$'`echo $PARAM`
        VALUE=`eval "echo $DOLLARPARAM"`
        printf "${PARAM}=\"${VALUE}\" "
    done
    echo
}

dumpenv_secret() {
    # same as dumpenv but doesn't write the value
    # this only gives indication if there is or isn't a value
    printf " -- "
    for PARAM in "$@"; do
        DOLLARPARAM='$'`echo $PARAM`
        VALUE=`eval "echo $DOLLARPARAM"`
        if [ "${VALUE}" != "" ]; then
            VALUE="*******"
        fi
        printf "${PARAM}=\"${VALUE}\" "
    done
    echo
}

bash_on_error() {
    # will open an upv bash terminal in case --debug --interactive were passed to ./upv.sh
    # can be used like this (from another function):
    # ! do_something && bash_on_error && return 1
    if [ "${UPV_DEBUG}" == "1" ] && [ "${UPV_INTERACTIVE}" == "1" ]; then
        dumpenv UPV_DEBUG UPV_INTERACTIVE
        echo "Starting bash on error"
        UPV_BASH="${UPV_BASH:-bash}"
        $UPV_BASH
    fi
    return 0
}

read_params() {
    # usage:
    # read_params PARAM_NAME PARAM_NAME..
    #
    # ensures all param names are set as environment variables
    # in interactive mode - will prompt to get missing variables
    #
    for PARAM in $*; do
        local VALUE=`eval 'echo $'${PARAM}`
        if [ "${VALUE}" == "" ]; then
            if [ "${UPV_INTERACTIVE}" == "0" ]; then
                error "Missing required param ${PARAM}"
                return 1
            else
                read -p "${PARAM}=" $PARAM
                export $PARAM
            fi
        fi
    done
    return 0
}

require_params() {
    # usage:
    # require_params PARAM_NAME PARAM_NAME..
    #
    # ensures all param names are set as environment variables
    #
    for PARAM in "$@"; do
        local VALUE=`eval 'echo $'${PARAM}`
        if [ "${VALUE}" == "" ]; then
            echo "Missing required env var: ${PARAM}"
            return 1
        fi
    done
    return 0
}

ensure_file_not_exists() {
    # gets list of files as params, ensures they don't exist (AKA deletes them)
    for PARAM in "$@"; do
        if [ -f "${PARAM}" ]; then
            rm -f "${PARAM}"
        fi
    done
    return 0
}

## functions for handling .env files (uses python-dotenv)

source_dotenv() {
    # set all environment variables from a .env file
    local ENV_FILE="${1:-.env}"
    [ ! -f "${ENV_FILE}" ] && touch "${ENV_FILE}"
    eval `dotenv -f "${ENV_FILE}" list`
}

dotenv_set() {
    # set an environment variable in a .env file
    local ENV_FILE="${1:-.env}"
    local KEY="${2}"
    local VAL="${3}"
    [ ! -f "${ENV_FILE}" ] && touch "${ENV_FILE}"
    if [ "${VAL}" == "" ]; then
        debug `dotenv -f "${ENV_FILE}" -qnever unset -- "${KEY}" 2>&1`
    else
        debug `dotenv -f "${ENV_FILE}" -qnever set -- "${KEY}" "${VAL}" 2>&1`
    fi
    return 0
}

dotenv_get() {
    # get an environment variable from a .env file
    local ENV_FILE="${1:-.env}"
    local KEY="${2}"
    local DEFAULT="${3}"
    VAL=`(
        source_dotenv "${ENV_FILE}"
        eval 'echo $'$KEY
    )`
    echo "${VAL:-$DEFAULT}"
}

## handling yaml files (using python yaml)

yaml_get() {
    # get an attribute from a yaml file
    local YAML_FILE="${1}"
    local KEY="${2}"
    local DEFAULT="${3}"
    local VAL=`python -c 'import yaml;print(yaml.load(open("'${YAML_FILE}'")).get("'${KEY}'", ""))'`
    echo "${VAL:-$DEFAULT}"
}

## simple daemon functionality, graceful termination handling

kill_pids() {
    # used by graceful_handler but can also be used directly
    # kills and waits for pids to stop
    local PIDS="${1}"
    if [ "${PIDS}" != "" ]; then
        echo "attempting to gracefuly kill and wait for pids (${PIDS})"
        for PID in $PIDS; do kill -TERM "${PIDS}"; done
        for PID in $PIDS; do wait "${PIDS}"; done
    fi
}

graceful_handler() {
    # can be used for simple daemon functionality, example usage:
    #
    # TEMPDIR=`mktemp -d`
    # do_something $TEMPDIR &
    # PIDS="${!}"
    # do_something_else $TEMPDIR &
    # PIDS+=" ${!}"
    # trap "echo 'caught SIGTERM, attempting graceful shutdown'; graceful_handler \"${PIDS}\" \"${TEMPDIR}\"" SIGTERM;
    # trap "echo 'caught SIGINT, attempting graceful shutdown'; graceful_handler \"${PIDS}\" \"${TEMPDIR}\"" SIGINT;
    # while true; do tail -f /dev/null & wait ${!}; done
    #
    local PIDS="${1}"
    local TEMPDIR="${2}"
    kill_pids "${PIDS}"
    [ "${TEMPDIR}" != "" ] && rm -rf $TEMPDIR
    exit 0
}

## code execution for upv modules

upv_exec_sanity() {
    # sanity checks before executing upv code
    local MODULE_PATH="${1}"
    [ ! -d "${UPV_ROOT}" ] && error "missing UPV_ROOT directory: ${UPV_ROOT}" && return 1
    [ ! -d "${UPV_WORKSPACE}" ] && error "missing UPV_WORKSPACE directory: ${UPV_WORKSPACE}" && return 1
    [ ! -d "${UPV_WORKSPACE}/${MODULE_PATH}" ] && error "missing MODULE_PATH directory: ${MODULE_PATH}" && return 1
    return 0
}

upv_start_bash() {
    # starts a bash terminal instantiated with upv environment
    local MODULE_PATH="${1}"
    local PARAMS="${2}"
    info "starting upv bash terminal"
    # upv code assume current directory is the module path
    pushd "${UPV_WORKSPACE}/${MODULE_PATH}" >/dev/null
        UPV_BASH="${UPV_BASH:-bash}"
        $UPV_BASH $PARAMS
        RES="$?"
    popd >/dev/null
    return "${RES}"
}

upv_exec() {
    # low-level upv code execution
    # this is called directly from upv/entrypoint.sh
    # it assumes we are inside the correct docker container for this module
    local MODULE_PATH="${1}"
    local CMD="${2}"
    local PARAMS="${3}"
    ! upv_exec_sanity "${MODULE_PATH}" && return 1
    # upv code assume current directory is the module path
    cd "${UPV_WORKSPACE}/${MODULE_PATH}"
    # code execution
    if [ "${CMD}" != "" ]; then
        if [ -f "${UPV_WORKSPACE}/${MODULE_PATH}/${CMD}.sh" ]; then
            "${UPV_WORKSPACE}/${MODULE_PATH}/${CMD}.sh" $PARAMS
            RES="$?"
        elif [ -f "${UPV_WORKSPACE}/${MODULE_PATH}/${CMD}.py" ]; then
            python "${UPV_WORKSPACE}/${MODULE_PATH}/${CMD}.py" $PARAMS
            RES="$?"
        elif [ -f "${UPV_ROOT}/${CMD}.sh" ]; then
            "${UPV_ROOT}/${CMD}.sh" $PARAMS
            RES="$?"
        elif [ -f "${UPV_ROOT}/${CMD}.py" ]; then
            python "${UPV_ROOT}/${CMD}.py" $PARAMS
            RES="$?"
        else
            $CMD $PARAMS
            RES="$?"
        fi
    else
        upv_start_bash "${MODULE_PATH}" "${PARAMS}"
        RES="$?"
    fi
    RES="$?"
    if [ "${RES}" != "0" ]; then
        error "upv execution failed `dumpenv UPV_ROOT UPV_WORKSPACE MODULE_PATH CMD PARAMS`"
    fi
    return "${RES}"
}

upv_build_docker() {
    # build a docker image for an upv module
    # outputs the built image id to stdout
    # all other output will be to stderr
    # empty output means build failed
    local MODULE_PATH="${1}"
    local BUILD_ARGS="${2}"
    ! upv_exec_sanity "${MODULE_PATH}" >/dev/stderr && return 1
    debug "upv_build_docker" >/dev/stderr
    # last image pulled for this module (by ./upv.sh --pull)
    local PULLED_TAG=`dotenv_get "${UPV_WORKSPACE}/${MODULE_PATH}/.env" "PULLED_TAG"`
    # optional custom Dockerfile (if empty, will try upv.Dockerfile and finally default to Dockerfile)
    local DOCKER_FILE=`yaml_get "${UPV_WORKSPACE}/${MODULE_PATH}/upv.yaml" "docker-file"`
    # last tag built locally for this module (by previous call to upv_build_docker)
    local LAST_BUILD_TAG=`dotenv_get "${MODULE_PATH}/.env" UPV_LAST_BUILD_TAG`
    debug "`dumpenv MODULE_PATH BUILD_ARGS PULLED_TAG DOCKER_FILE LAST_BUILD_TAG`" >/dev/stderr
    local CACHE_FROM=""
    if [ "${UPV_STRICT}" == "1" ]; then
        info "Strict mode: using --cache-from docker build arg" >/dev/stderr
        # UPV_STRICT should be set by automated CI tools, to use specific cache sources for security
        # for local development it's too cumbersome and causes long unnecesarry rebuilds
        if [ "${PULLED_TAG}" != "" ]; then
            local CACHE_FROM+=" --cache-from ${PULLED_TAG}"
        fi
        if [ "${LAST_BUILD_TAG}" != "" ]; then
            local CACHE_FROM+=" --cache-from ${LAST_BUILD_TAG}"
        fi
    else
        debug "Not using --cache-from docker build arg" >/dev/stderr
    fi
    if [ "${DOCKER_FILE}" == "" ]; then
        if [ -f "${PWD}/${MODULE_PATH}/upv.Dockerfile" ]; then
            local DOCKER_FILE="upv.Dockerfile"
        else
            local DOCKER_FILE="Dockerfile"
        fi
    fi
    [ ! -f "${UPV_WORKSPACE}/${MODULE_PATH}/${DOCKER_FILE}" ] &&\
        error "missing docker file: ${UPV_WORKSPACE}/${MODULE_PATH}/${DOCKER_FILE}" >/dev/stderr && return 1
    debug "`dumpenv DOCKER_FILE`" >/dev/stderr
    TEMPDIR=`mktemp -d`
    BUILD_LOG_FILE="${TEMPDIR}/build.log"
    IIDFILE="${TEMPDIR}/iidfile"
    local CMD="docker build ${CACHE_FROM} ${BUILD_ARGS} --iidfile ${IIDFILE} -f ${UPV_WORKSPACE}/${MODULE_PATH}/${DOCKER_FILE} ${UPV_WORKSPACE}/${MODULE_PATH}"
    debug `dumpenv BUILD_LOG_FILE IIDFILE CMD` >/dev/stderr
    if [ "${UPV_DEBUG}" == "1" ]; then
        $CMD | tee /dev/stderr > "${BUILD_LOG_FILE}"
        BUILD_RES="${PIPESTATUS[0]}"
    else
        $CMD > "${BUILD_LOG_FILE}"
        BUILD_RES="$?"
    fi
    if [ "${BUILD_RES}" == "0" ]; then
        local DOCKER_TAG=`cat $IIDFILE`
        echo "${DOCKER_TAG}"
        dotenv_set "${UPV_WORKSPACE}/${MODULE_PATH}/.env" "UPV_LAST_BUILD_TAG" "${DOCKER_TAG}" >/dev/stderr
        rm -rf "${TEMPDIR}"
        return 0
    else
        dotenv_set "${UPV_WORKSPACE}/${MODULE_PATH}/.env" "UPV_LAST_BUILD_TAG" "" >/dev/stderr
        cat "${BUILD_LOG_FILE}" >/dev/stderr
        error "Build failed" >/dev/stderr
        error `dumpenv CMD` >/dev/stderr
        return 1
    fi
}

upv_build_root_docker_image() {
    debug "Building root upv image" >/dev/stderr
    local ROOT_UPV_TAG=`upv_build_docker "upv"`
    [ "${ROOT_UPV_TAG}" == "" ] && error "Failed to build root upv docker image" >/dev/stderr && return 1
    echo "${ROOT_UPV_TAG}"
    return 0
}

upv_build_base_docker_image() {
    debug "Building base upv image" >/dev/stderr
    local ROOT_UPV_TAG="${1}"
    local BASE_UPV_TAG=`upv_build_docker "." "--build-arg ROOT_UPV_TAG=${ROOT_UPV_TAG}"`
    [ "${BASE_UPV_TAG}" == "" ] && error "Failed to build base upv docker image" >/dev/stderr && return 1
    echo "${BASE_UPV_TAG}"
    return 0
}

upv_build_module_docker_image() {
    debug "Building module upv image" >/dev/stderr
    local ROOT_UPV_TAG="${1}"
    local BASE_UPV_TAG="${2}"
    local MODULE_PATH="${3}"
    if [ "${MODULE_PATH}" == "." ]; then
        echo "${BASE_UPV_TAG}"
    elif [ "${MODULE_PATH}" == "upv" ]; then
        echo "${ROOT_UPV_TAG}"
    else
        local MODULE_TAG=`upv_build_docker "${MODULE_PATH}" "--build-arg BASE_UPV_TAG=${BASE_UPV_TAG} --build-arg ROOT_UPV_TAG=${ROOT_UPV_TAG}"`
        [ "${MODULE_TAG}" == "" ] && error "Failed to build module upv docker image" >/dev/stderr && return 1
        echo "${MODULE_TAG}"
        return 0
    fi
}

upv_start_docker() {
    # build and starts the upv docker container
    # function can run on host machine or inside an upv container (using sibling dockers)
    # returns 0 = handled start successfully, 1 = failed to start
    local MODULE_PATH="${1}"
    local CMD="${2}"
    local PARAMS="${3}"
    debug "upv_start_docker `dumpenv MODULE_PATH CMD PARAMS`"
    local ROOT_UPV_TAG=`upv_build_root_docker_image`; [ "${ROOT_UPV_TAG}" == "" ] && return 1
    local BASE_UPV_TAG=`upv_build_base_docker_image "${ROOT_UPV_TAG}"`; [ "${BASE_UPV_TAG}" == "" ] && return 1
    local MODULE_TAG=`upv_build_module_docker_image "${ROOT_UPV_TAG}" "${BASE_UPV_TAG}" "${MODULE_PATH}"`; [ "${MODULE_TAG}" == "" ] && return 1
    debug `dumpenv ROOT_UPV_TAG BASE_UPV_TAG MODULE_TAG`
    debug "Running upv image: ${MODULE_TAG}"
    # upv container docker run logic:
    #  - network host - allows to start dev servers or otherwise interact with the container
    #                   upv is intended as a build environment, so this won't be the actual deployed images configuration
    #  - /upv/workspace volume - this allows upv modules to access the shared project files
    #  - docker.sock, .docker - allows upv to start sibling docker containers and share the docker build environment
    #  - UPV_DEBUG, UPV_INTERACTIVE - set globally based on --debug and --interactive parameters to ./upv.sh
    #  - UPV_WORKSPACE - absolute workspace directory - hard-coded to /upv/workspace
    #  - UPV_HOST_WORKSPACE - absolute workspace directory inside the host machine - allows upv modules to start sibling containers
    #  - UPV_ROOT - absolute directory to the root upv module inside the upv workspace
    docker run -it --rm --network host \
               -v "/var/run/docker.sock:/var/run/docker.sock" \
               -v "${UPV_HOST_WORKSPACE:-$UPV_WORKSPACE}:/upv/workspace" \
               -v "${UPV_HOST_HOME:-$HOME}/.docker:/root/.docker" \
               -e "UPV_HOST_WORKSPACE=${UPV_HOST_WORKSPACE:-$UPV_WORKSPACE}" \
               -e "UPV_HOST_HOME=${UPV_HOST_HOME:-$HOME}" \
               -e "UPV_DEBUG=${UPV_DEBUG}" \
               -e "UPV_INTERACTIVE=${UPV_INTERACTIVE}" \
               -e "UPV_STRICT=${UPV_STRICT}" \
               -e "UPV_WORKSPACE=/upv/workspace" \
               -e "UPV_ROOT=/upv/workspace/upv" \
               "${MODULE_TAG}" "${MODULE_PATH}" "${CMD}" "${PARAMS}"
    RES="$?"
    if [ "${RES}" != "0" ]; then
        echo "Upv exited with error code ${RES}"
        return 1
    else
        debug "Upv exited with successful return code ${RES}"
        return 0
    fi
}

docker_clean_github_build() {
    # performs a clean build from a github repo
    local GITHUB_REPO="${1}"
    local GITHUB_BRANCH="${2}"
    local DOCKER_TAG="${3}"
    local DOCKER_FILE="${4}"
    local DOCKER_DIR="${5}"
    TEMPDIR=`mktemp -d`
    git clone --branch "${GITHUB_BRANCH}" "https://github.com/${GITHUB_REPO}.git" "${TEMPDIR}"
    echo "docker build -t \"${DOCKER_TAG}\" -f \"${DOCKER_FILE}\" \"${TEMPDIR}/${DOCKER_DIR}\""
    docker build -t "${DOCKER_TAG}" -f "${TEMPDIR}/${DOCKER_FILE}" "${TEMPDIR}/${DOCKER_DIR}"
}

#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

UPV_MODULE_PATH="${1}"
CMD="${2}"
PARAMS="${3}"

debug "upv entrypoint"
debug `dumpenv UPV_MODULE_PATH CMD PARAMS`
debug `dumpenv UPV_ROOT UPV_WORKSPACE`

if [ "${CMD}" == "" ] && [ "`upv_get_exec_alias $UPV_MODULE_PATH`" == "" ]; then
    debug "upv_start_bash from entrypoint"
    upv_start_bash "${UPV_MODULE_PATH}"
else
    upv "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
fi

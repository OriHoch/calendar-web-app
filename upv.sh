#!/usr/bin/env bash

export UPV_ROOT="`pwd`/upv"
export UPV_WORKSPACE=`pwd`

source "${UPV_ROOT}/functions.sh"
source "${UPV_ROOT}/bootstrap_functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

! upv_sh_read_params "$@" && error "Failed to read arguments" && exit 1
! upv_sh_preflight && error "Failed preflight checks" && exit 1

upv_sh_handle_pull "$@"; RES="$?"; [ "${RES}" != "2" ] && exit "${RES}"
upv_sh_handle_push "$@"; RES="$?"; [ "${RES}" != "2" ] && exit "${RES}"
upv_sh_handle_help "$@"; RES="$?"; [ "${RES}" != "2" ] && exit "${RES}"

upv_start_docker "${UPV_MODULE_PATH}" "${CMD}" "${PARAMS}"
RES="$?"

upv_sh_restore_permissions

exit "${RES}"

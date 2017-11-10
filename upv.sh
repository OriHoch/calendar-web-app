#!/usr/bin/env bash
#
#
# What is upv?
#
# `upv` is a framework that enables modularity and reusability of code, documentation and best practices.
#
# It provides a minimal common layer, combined with tools, conventions and best practices.
#
#
# upv objectives
#
# Optimize the following processes:
#
# * *POC* - turning an abstract idea to concrete POC implementation or research
# * *Implementation* - Converting the POC to a concrete stable, deployable implementation
# * *Scale* - Scaling up the implementation to handle higher load / data / change requirements
# * *Support* - Supporting the project in the long-term - project management, monitoring, alerts, etc..
#
# Upv concepts and tools
# `./upv.sh` - the main entrypoint to the upv framework, should exist in the root of every upv project
# `upv project` - usually corresponds to a Git repository
# `upv module` - a sub-directory inside an `upv project`
# `upv.yaml` - may be present in the root directory of an `upv module`
#              provides metadata / static configurations for the module
#
#
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

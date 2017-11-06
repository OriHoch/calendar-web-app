#!/usr/bin/env bash

source upv/functions.sh
source upv/bootstrap_functions.sh
source functions.sh

upv_sh_handle_pull "$@" && exit 0

! upv_sh_read_params "$@" &&\
    error "Failed to read arguments" && exit 1

! upv_sh_preflight &&\
    error "Failed preflight checks" && exit 1

! require_params UPV_MODULE_PATH &&\
    upv_sh_help && exit 1

upv_sh_start . upv.Dockerfile

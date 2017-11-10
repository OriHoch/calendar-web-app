#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

! upv_exec . serve_preflight &&\
    error "Serve failed" && exit 1

upv_exec . serve_start "$@"

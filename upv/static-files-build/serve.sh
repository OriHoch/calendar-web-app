#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

! upv . serve_preflight &&\
    error "Serve failed" && exit 1

upv . serve_start "$@"

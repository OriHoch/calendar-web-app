#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

if [ "${1}" != "" ]; then
    echo "Rebuilding, changed file = ${1}"
fi

info "Building static files"

! upv_exec . static_files_build &&\
    error "Failed static files build" && exit 1

success
exit 0

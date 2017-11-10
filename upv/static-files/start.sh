#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

./build.sh && ./serve.sh & upv_exec . static_files_watch_changes

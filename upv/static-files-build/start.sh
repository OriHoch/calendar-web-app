#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

upv build && upv serve & upv . static_files_watch_changes

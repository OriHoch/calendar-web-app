#!/bin/bash
source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"
upv_exec "$@"
exit "$?"

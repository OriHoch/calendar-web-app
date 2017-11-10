#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"
source "functions.sh"

enable_travis

info "Please input your docker username and password"
info "They will be stored as travis secured environment variables and used by deploy script"
read -p "Docker Hub User: "
echo
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public DOCKER_HUB_USER "${REPLY}"
read -s -p "Docker Hub Password: "
echo
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --private DOCKER_HUB_PASS "${REPLY}"

success "Provisionining complete, you can now run push script on Travis-CI (based on travis env)"

exit 0

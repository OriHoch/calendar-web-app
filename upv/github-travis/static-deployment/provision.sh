#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"
source "functions.sh"

enable_travis

if [ "${GITHUB_TOKEN}" == "" ]; then
    info "We can't automate creation of GitHub machine users due to the GitHub terms of use"
    info "Please create a machine user and give that user full write permissiosn on the repo"
    info "Input this user's token here"
    ! read_params GITHUB_TOKEN && exit 1
fi

if [ "${GIT_CONFIG_USER}" == "" ] || [ "${GIT_CONFIG_EMAIL}" == "" ]; then
    info "Please input the git user and email which will appear in commits made by the machine user"
    ! read_params GIT_CONFIG_USER GIT_CONFIG_EMAIL && exit 1
fi

dotenv_set "" GITHUB_TOKEN "${GITHUB_TOKEN}"
dotenv_set "" GIT_CONFIG_USER "${GIT_CONFIG_USER}"
dotenv_set "" GIT_CONFIG_EMAIL "${GIT_CONFIG_EMAIL}"

travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --private GITHUB_TOKEN "${GITHUB_TOKEN}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GIT_CONFIG_USER "${GIT_CONFIG_USER}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GIT_CONFIG_EMAIL "${GIT_CONFIG_EMAIL}"

success "Provisionining complete, you can now run deploy script locally (based on .env file) or on Travis-CI (based on travis env)"

exit 0

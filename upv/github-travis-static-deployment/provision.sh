#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

source_dotenv

! read_params GITHUB_REPO_SLUG && exit 1

dotenv_set "" GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}"

[ "${UPV_INTERACTIVE}" != "1" ] &&\
    error "Only interactive provisioning is supported" && exit 1

info "Please log-in with your personal GitHub credentials"
info "The credentials are used directly to Travis CLI and from there directly to GitHub API"
! travis login --no-interactive &&\
    error "failed to login to travis" && exit 1

info "Enabling travis for repo ${GITHUB_REPO_SLUG}"
! travis enable --no-interactive --repo "${GITHUB_REPO_SLUG}" &&\
    error "Failed to enable repo in travis, make sure you have right permissions and auth" && exit 1

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

if [ "${GITHUB_PUSH_BRANCH}" == "" ]; then
    info "Please input the default branch name"
    info "This will usually be 'master'"
    ! read_params GITHUB_PUSH_BRANCH && exit 1
fi

dotenv_set "" GITHUB_TOKEN "${GITHUB_TOKEN}"
dotenv_set "" GIT_CONFIG_USER "${GIT_CONFIG_USER}"
dotenv_set "" GIT_CONFIG_EMAIL "${GIT_CONFIG_EMAIL}"
dotenv_set "" GITHUB_PUSH_BRANCH "${GITHUB_PUSH_BRANCH}"

travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --private GITHUB_TOKEN "${GITHUB_TOKEN}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GIT_CONFIG_USER "${GIT_CONFIG_USER}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GIT_CONFIG_EMAIL "${GIT_CONFIG_EMAIL}"
travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GITHUB_PUSH_BRANCH "${GITHUB_PUSH_BRANCH}"

success "Provisionining complete, you can now run deploy script locally (based on .env file) or on Travis-CI (based on travis env)"

exit 0

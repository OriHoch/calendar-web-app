#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"
source "functions.sh"

[ "${UPV_INTERACTIVE}" != "1" ] && error "Only interactive provisioning is supported" && exit 1
! travis_init && exit 1
dotenv_set "" GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}"
dotenv_set "" GITHUB_MASTER_BRANCH "${GITHUB_MASTER_BRANCH}"
! travis_login && exit 1

info "Enabling travis for repo ${GITHUB_REPO_SLUG}"
! travis enable --no-interactive --repo "${GITHUB_REPO_SLUG}" &&\
    error "Failed to enable repo in travis, make sure you have right permissions and auth" && exit 1

! travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" \
    --public GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}" && exit 1
! travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" \
    --public GITHUB_MASTER_BRANCH "${GITHUB_MASTER_BRANCH}" && exit 1

echo "Setting UPV_STRICT=1 on Travis-CI - to force upv strict mode when running on travis"
! travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" \
    --public UPV_STRICT "1" && exit 1

echo "Setting UPV_INTERACTIVE=0 on Travis-CI - to prevent upv framework from interactively asking for values"
! travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" \
    --public UPV_INTERACTIVE "0" && exit 1

success "Provisioned GitHub and Travis-CI integration"
exit 0

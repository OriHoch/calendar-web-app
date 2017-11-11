#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

deploy() {
    local BRANCH="${1}"
    local REPO="${2}"
    local GIT_EMAIL="${3}"
    local GIT_USER="${4}"
    local GITHUB_TOKEN="${5}"
    info "Starting github travis static deployment"
    ! upv_exec . deploy_preflight_checks &&\
        error "Failed deployment preflight checks" && return 1
    TEMPDIR=`mktemp -d`
    local CLONE_URL="https://github.com/${REPO}.git"
    ! git clone --branch "${BRANCH}" "${CLONE_URL}" "${TEMPDIR}" &&\
        error "Failed to clone from ${CLONE_URL} branch ${BRANCH}" && return 1
    ! upv_exec . deploy_copy "${TEMPDIR}" &&\
        error "Failed to copy deployment files" && return 1
    pushd "${TEMPDIR}" >/dev/null
        if deploy_has_changes; then
            info "Starting deployment - committing changes to GitHub"
            deploy_add_changes
            git status
            git config user.email "${GIT_EMAIL}"
            git config user.name "${GIT_USER}"
            # --no-deploy should be read by CI tools to prevent infinite deploy loops or to allow manual deployment flows
            git commit -m "deploy script - committing changes --no-deploy"
            ! git push "https://${GITHUB_TOKEN}@github.com/${REPO}.git" "HEAD:${BRANCH}" &&\
                error "Failed to push to https://****@github.com/${REPO}.git HEAD:${BRANCH}" && return 1
        else
            info "no changes - skipping deployment"
        fi
    popd >/dev/null
    success "Deployment complete"
    return 0
}

! source_dotenv && exit 1

! require_params GITHUB_REPO_SLUG GITHUB_TOKEN GIT_CONFIG_USER GIT_CONFIG_EMAIL GITHUB_MASTER_BRANCH &&\
    error "Please run provision script first" && exit 1

if [ "${TRAVIS}" == "true" ]; then
    if [ "${TRAVIS_PULL_REQUEST}" == "false" ] &&\
       [ "${TRAVIS_BRANCH}" == "${GITHUB_MASTER_BRANCH}" ] &&\
       ! echo "${TRAVIS_COMMIT_MESSAGE}" | grep -- "--no-deploy" >/dev/null
    then
        # not a pull request
        # on master branch
        # doesn't have --no-deploy switch
        ! deploy "${GITHUB_MASTER_BRANCH}" "${GITHUB_REPO_SLUG}" "${GIT_CONFIG_EMAIL}" "${GIT_CONFIG_USER}" "${GITHUB_TOKEN}" &&\
            exit 1
    else
        info "Skipping deployment"
    fi
else
    # called from ./upv.sh cli - not from travis
    ! deploy "${GITHUB_MASTER_BRANCH}" "${GITHUB_REPO_SLUG}" "${GIT_CONFIG_EMAIL}" "${GIT_CONFIG_USER}" "${GITHUB_TOKEN}" &&\
        exit 1
fi

exit 0

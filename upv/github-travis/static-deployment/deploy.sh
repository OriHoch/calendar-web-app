#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

source_dotenv

deploy() {
    info "Starting github travis static deployment"
    ! require_params GITHUB_REPO_SLUG GITHUB_TOKEN GIT_CONFIG_USER GIT_CONFIG_EMAIL GITHUB_MASTER_BRANCH &&\
        error "Please run provision script first" && return 1
    ! upv_exec . deploy_preflight_checks &&\
        error "Failed deployment preflight checks" && return 1
    TEMPDIR=`mktemp -d`
    ! git clone --branch "${GITHUB_MASTER_BRANCH}" "https://github.com/${GITHUB_REPO_SLUG}.git" "${TEMPDIR}" &&\
        error "Failed to clone from https://github.com/${GITHUB_REPO_SLUG}.git branch ${GITHUB_MASTER_BRANCH}" && return 1
    ! upv_exec . deploy_copy "${TEMPDIR}" &&\
        error "Failed to copy deployment files" && return 1
    pushd "${TEMPDIR}" >/dev/null
        if deploy_has_changes; then
            info "Starting deployment - committing changes to GitHub"
            deploy_add_changes
            git status
            git config user.email "${GIT_CONFIG_EMAIL}"
            git config user.name "${GIT_CONFIG_USER}"
            # --no-deploy should be read by CI tools to prevent infinite deploy loops or to allow manual deployment flows
            git commit -m "deploy script - committing changes --no-deploy"
            ! git push "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO_SLUG}.git" "HEAD:${GITHUB_MASTER_BRANCH}" &&\
                error "Failed to push to https://****@github.com/${GITHUB_REPO_SLUG}.git HEAD:${GITHUB_MASTER_BRANCH}" && return 1
        else
            info "no changes - skipping deployment"

        fi
    popd >/dev/null
    success "Deployment complete"
    return 0
}

if [ "${TRAVIS}" == "true" ]; then
    if [ "${TRAVIS_PULL_REQUEST}" == "false" ] &&\
       [ "${TRAVIS_BRANCH}" == "${GITHUB_MASTER_BRANCH}" ] &&\
       ! echo "${TRAVIS_COMMIT_MESSAGE}" | grep -- "--no-deploy" >/dev/null
    then
        # not a pull request
        # on master branch
        # doesn't have --no-deploy switch
        ! deploy && exit 1
    else
        info "Skipping deployment"
    fi
else
    # called from ./upv.sh cli - not from travis
    ! deploy && exit 1
fi

exit 0

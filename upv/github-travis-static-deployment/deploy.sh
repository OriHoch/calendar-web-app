#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

source_dotenv

if [ "${TRAVIS}" == "true" ]; then
    if [ "${TRAVIS_PULL_REQUEST}" == "false" ] &&\
       ! echo "${TRAVIS_COMMIT_MESSAGE}" | grep -- "--no-deploy" >/dev/null
    then
        # not a pull request
        # doesn't have --no-deploy switch
        # we override some env vars - to allow building to any repo / branch based on travis env vars
        export GITHUB_REPO_SLUG="${TRAVIS_REPO_SLUG}"
        export GITHUB_PUSH_BRANCH="${TRAVIS_BRANCH}"
    else
        info "Skipping deployment"
        exit 0
    fi
elif [ "${1}" != "" ]; then
    export GITHUB_PUSH_BRANCH="${1}"
    info `dumpenv GITHUB_PUSH_BRANCH`
fi

! require_params GITHUB_REPO_SLUG GITHUB_TOKEN GIT_CONFIG_USER GIT_CONFIG_EMAIL GITHUB_PUSH_BRANCH &&\
    error "Please run provision script first" && exit 1

! upv . deploy_preflight_checks &&\
    error "Failed deployment preflight checks" && exit 1

TEMPDIR=`mktemp -d`
! git clone --branch "${GITHUB_PUSH_BRANCH}" "https://github.com/${GITHUB_REPO_SLUG}.git" "${TEMPDIR}" &&\
    error "Failed to clone from https://github.com/${GITHUB_REPO_SLUG}.git branch ${GITHUB_PUSH_BRANCH}" && exit 1

! upv . deploy_copy "${TEMPDIR}" &&\
    error "Failed to copy deployment files" && exit 1

pushd "${TEMPDIR}" >/dev/null
    if deploy_has_changes; then
        info "Starting deployment - committing changes to GitHub"
        deploy_add_changes
        git status
        git config user.email "${GIT_CONFIG_EMAIL}"
        git config user.name "${GIT_CONFIG_USER}"
        # --no-deploy should be read by CI tools to prevent infinite deploy loops or to allow manual deployment flows
        git commit -m "deploy script - committing changes --no-deploy"
        ! git push "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO_SLUG}.git" "HEAD:${GITHUB_PUSH_BRANCH}" &&\
            error "Failed to push to https://****@github.com/${GITHUB_REPO_SLUG}.git HEAD:${GITHUB_PUSH_BRANCH}" && exit 1
    else
        info "skipping deployment"
    fi
popd >/dev/null

success "Deployment complete"

exit 0

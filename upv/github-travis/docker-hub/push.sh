#!/usr/bin/env bash

source "${UPV_ROOT}/functions.sh"
source "${UPV_WORKSPACE}/functions.sh"

! source_dotenv && exit 1

if [ "${TRAVIS}" == "true" ]; then
    if [ "${TRAVIS_PULL_REQUEST}" == "false" ] &&\
       [ "${TRAVIS_BRANCH}" == "${GITHUB_MASTER_BRANCH}" ]
    then
        # not a pull request + on master branch
        info "Pushing images to Docker Hub"
        if [ "${DOCKER_HUB_USER}" != "" ] && [ "${DOCKER_HUB_PASS}" != "" ]; then
            ! docker login --username "${DOCKER_HUB_USER}" --password "${DOCKER_HUB_PASS}" &&\
                error "Failed to login to docker hub" && exit 1
            cd "${UPV_WORKSPACE}"
            ! ./upv.sh --push && error "Failed push" && exit 1
            success
        else
            error "Missing required environment variables, run provision script first"
            exit 1
        fi
    fi
else
    ! docker login && error "Failed to login to docker hub" && exit 1
    cd "${UPV_WORKSPACE}"
    ! ./upv.sh --push && error "Failed push" && exit 1
    success
fi

exit 0

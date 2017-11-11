#!/usr/bin/env bash

GITHUB_TRAVIS_DIR="${1}"

[ "${GITHUB_TRAVIS_DIR}" == "" ] && exit 1

echo "Installing system dependencies"
! sudo apt-get install jq uuid-runtime && exit 1

echo "Installing Docker"
! (curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&\
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&\
   sudo apt-get update &&\
   sudo apt-get -y install docker-ce) && exit 1

echo "Installing System Python dependencies"
! (sudo pip install --upgrade pip setuptools &&\
   sudo pip install python-dotenv pyyaml) && exit 1

echo "Creating .env file from travis vars"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "GITHUB_REPO_SLUG" "${GITHUB_REPO_SLUG}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "GITHUB_MASTER_BRANCH" "${GITHUB_MASTER_BRANCH}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "UPV_STRICT" "${UPV_STRICT}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "UPV_INTERACTIVE" "${UPV_INTERACTIVE}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "DOCKER_HUB_USER" "${DOCKER_HUB_USER}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "DOCKER_HUB_PASS" "${DOCKER_HUB_PASS}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "GITHUB_TOKEN" "${GITHUB_TOKEN}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "GIT_CONFIG_USER" "${GIT_CONFIG_USER}"
dotenv -f "${GITHUB_TRAVIS_DIR}/.env" -qnever set "GIT_CONFIG_EMAIL" "${GIT_CONFIG_EMAIL}"

exit 0

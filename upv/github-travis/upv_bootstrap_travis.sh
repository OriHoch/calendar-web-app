#!/usr/bin/env bash

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

exit 0

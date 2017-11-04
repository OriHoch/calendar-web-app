#!/usr/bin/env bash

docker build -t orihoch/calendar-web-app-upv -f upv.Dockerfile .
docker push orihoch/calendar-web-app-upv

#!/usr/bin/env bash

mkdir -p dist
cd dist && pipenv run python -m http.server $*

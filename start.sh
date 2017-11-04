#!/usr/bin/env bash

./build.sh && ./serve.sh & pipenv run when-changed *.sh *.py *.yaml *.css templates/*.html -c ./build.sh %f

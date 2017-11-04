#!/usr/bin/env bash

if [ "${1}" != "" ]; then
    echo "Rebuilding, changed file = ${1}"
fi

mkdir -p dist
echo "Copying main.css to dist/main.css"
cp main.css dist/main.css
./dpp.sh run ./build

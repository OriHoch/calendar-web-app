
# runs from /upv/workspace - make sure we are ready to deploy
deploy_preflight_checks() {
    [ ! -f dist/index.html ] &&\
        error "Please run build before deploy" && return 1
    [ ! -f data/sheet-1.csv ] &&\
        error "Please run download before deploy" && return 1
    [ ! -f datapackage.json ] &&\
        error "Please run download before deploy" && return 1
    return 0
}

# runs from /upv/workspace - can be used to build / copy artifacts to the given temp dir
deploy_copy() {
    local TEMPDIR="${1}"
    rm -rf "${TEMPDIR}/dist" &&\
    rm -rf "${TEMPDIR}/data" &&\
    rm -f "${TEMPDIR}/datapackage.json" &&\
    cp -r dist "${TEMPDIR}/" &&\
    cp -r data "${TEMPDIR}/" &&\
    cp datapackage.json "${TEMPDIR}/"
}

# runs from the temporary directory with the copied artifacts
deploy_has_changes() {
    if ! git diff --exit-code dist/ data/ datapackage.json; then
        info "Detected changes in dist/, data/ or datapackage.json"
        return 0
    else
        info "No changes in dist/, data/ or datapackage.json"
        return 1
    fi
}

# runs from the temporary directory with the copied artifacts
deploy_add_changes() {
    git add dist/ data/ datapackage.json
}

static_files_build(){
    mkdir -p dist
    echo "Copying main.css to dist/main.css"
    cp main.css dist/main.css
    pipenv run dpp run ./build
}

static_files_watch_changes() {
    pipenv run when-changed *.sh *.py *.yaml *.css templates/*.html -c ./upv.sh build %f
}

serve_preflight() {
    test -f dist/index.html
}

serve_start() {
    cd dist && pipenv run python -m http.server "$@"
}

upv_pull() {
    docker pull orihoch/calendar-web-app-upv
}

upv_push() {
    docker_clean_github_build OriHoch/calendar-web-app master orihoch/calendar-web-app-upv upv.Dockerfile .
    docker push orihoch/calendar-web-app-upv
}

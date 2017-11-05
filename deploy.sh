#!/usr/bin/env bash

source upv/functions.sh

source_dotenv

! require_params GITHUB_REPO_SLUG GITHUB_TOKEN GIT_CONFIG_USER GIT_CONFIG_EMAIL GITHUB_PUSH_BRANCH &&\
    error "Please run provision script first" && exit 1

[ ! -f dist/index.html ] &&\
    error "Please run build before deploy" && exit 1

[ ! -f data/sheet-1.csv ] &&\
    error "Please run download before deploy" && exit 1

# we use GitHub pages static html files for deployment
# so we clone the repo, modify and commit the changes (if needed)
TEMPDIR=`mktemp -d`
! git clone "https://github.com/${GITHUB_REPO_SLUG}.git" "${TEMPDIR}" &&\
    error "Failed to clone from https://github.com/${GITHUB_REPO_SLUG}.git" && exit 1

rm -rf "${TEMPDIR}/dist"
rm -rf "${TEMPDIR}/data"
cp -r dist "${TEMPDIR}/"
cp -r data "${TEMPDIR}/"

pushd "${TEMPDIR}" >/dev/null
    if ! git diff --exit-code dist/ data/; then
        info "Committing dist/ and data/ changes to GitHub"
        git add dist/ data/
        git status
        git config user.email "${GIT_CONFIG_EMAIL}"
        git config user.name "${GIT_CONFIG_USER}"
        # --no-deploy should be read by CI tools to prevent infinite deploy loops or to allow manual deployment flows
        git commit -m "deploy script - committing changes in dist/ and data/ directories --no-deploy"
        ! git push "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO_SLUG}.git" "HEAD:${GITHUB_PUSH_BRANCH}" &&\
            error "Failed to push to https://****@github.com/${GITHUB_REPO_SLUG}.git HEAD:${GITHUB_PUSH_BRANCH}" && exit 1
    else
        info "No changes in data/ or dist/, skipping deployment"
    fi
popd >/dev/null

success "Deployment complete"

exit 0

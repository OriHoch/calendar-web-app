
enable_travis() {
    [ "${UPV_INTERACTIVE}" != "1" ] && error "Only interactive provisioning is supported" && return 1
    ! source_dotenv && return 1
    ! read_params GITHUB_REPO_SLUG GITHUB_MASTER_BRANCH && return 1
    dotenv_set "" GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}"
    dotenv_set "" GITHUB_MASTER_BRANCH "${GITHUB_MASTER_BRANCH}"
    info "Please log-in with your personal GitHub credentials"
    info "The credentials are used directly to Travis CLI and from there directly to GitHub API"
    ! travis login --no-interactive && error "failed to login to travis" && return 1
    info "Enabling travis for repo ${GITHUB_REPO_SLUG}"
    ! travis enable --no-interactive --repo "${GITHUB_REPO_SLUG}" &&\
        error "Failed to enable repo in travis, make sure you have right permissions and auth" && return 1
    ! travis env set --no-interactive --repo "${GITHUB_REPO_SLUG}" --public GITHUB_REPO_SLUG "${GITHUB_REPO_SLUG}" && return 1
    ! travis env set --no-interactive --repo "${GITHUB_MASTER_BRANCH}" --public GITHUB_MASTER_BRANCH "${GITHUB_MASTER_BRANCH}" && return 1
    return 0
}

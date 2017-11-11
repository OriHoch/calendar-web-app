travis_login() {
    info "Please log-in with your personal GitHub credentials"
    info "The credentials are used directly to Travis CLI and from there directly to GitHub API"
    ! travis login --no-interactive && error "failed to login to travis" && return 1
    return 0
}

travis_init() {
    ! source_dotenv && return 1
    ! read_params GITHUB_REPO_SLUG GITHUB_MASTER_BRANCH && return 1
    return 0
}

# Upv framework services for interacting with GitHub and Travis-CI

## Bootstrapping the upv environment in docker

Provision the GitHub and Travis-CI configuration (will ask for GitHub credentials):

```
./upv.sh upv/github-travis provision
```

Example .travis.yml bootstrapping the upv framework -

```
language: bash
sudo: required
script:
# bootstrap the upv travis environment
- upv/github-travis/upv_bootstrap_travis.sh
# pull images to speed-up the build
- ./upv.sh --pull
# additional ./upv.sh calls
```

## Push to Docker Hub

Push upv images to Docker Hub. Stores Docker Hub credentials securely in Travis CI

Provision (will ask for Docker Hub credentials)

```
./upv.sh upv/github-travis docker-hub/provision
```

Push to Docker Hub (when run locally - will ask for Docker Hub credentials)

```
./upv.sh upv/github-travis docker-hub/push
```

Add to .travis.yml (will only run for merges to master branch)

```
script:
- ./upv.sh upv/github-travis docker-hub/push
```

## Static deployment to GitHub

Provides a simple deployment flow, suitable for continuous deployment of artifacts to GitHub.

You should create a GitHub machine user - which will be used to commit build artifacts from Travis.

See [here](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) for details.

Provision (will ask for GitHub machine user token as well as other configurations)

```
./upv.sh upv/github-travis static-deployment/provision
```

Deploy (will commit and push build artifacts from current branch to master branch)

```
./upv.sh upv/github-travis static/deployment/deploy
```

Add to .travis.yml (will only run for merges to master branch)

```
script:
- ./upv.sh upv/github-travis static/deployment/deploy
```

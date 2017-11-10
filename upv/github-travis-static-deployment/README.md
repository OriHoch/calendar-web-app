# Deployment flow based on GitHub, Travis-CI and static files
Provides a simple deployment flow, suitable for continuous deployment of artifacts to GitHub.

## Usage

First, you should create a GitHub machine user - which will be used to commit build artifacts from Travis.

See [here](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) for details.

Once you have a GitHub token for a machine user, you can continue with the provision script:

```
./upv.sh --pull
./upv.sh --interactive upv/github-travis-static-deployment provision
```

You can now run the deploy script locally (based on the .env file created by provision script):

```
./upv.sh upv/github-travis-static-deployment provision deploy
```

Optionally, add an alias to upv.yaml:
```
aliases:
  deploy: ["upv/github-travis-static-deployment", "deploy"]
```

Then you can run:

```
./upv.sh deploy
```

You can also run it from .travis.yml (all environment variables are set on Travis by the provision script)

```
script:
- ./upv.sh deploy
```

## Security

The provision script creates a `.env` file with the github token - you should keep this file secure or even delete it and keep the values in Travis.

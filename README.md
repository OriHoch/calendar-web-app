# calendar-web-app
Static HTML web app that allows to show calendar appointments from verstaile input data sources (using Datapackage Pipelines ETL framework)

## Prerequisites

* Linux
* Docker
* System Python 2.7

## Installation

Pull the docker image and try to interactively install if some dependencies are missing.

```
./upv.sh --pull --interactive
```

## Usage

```
./upv.sh start
```

This runs the build pipeline, watches and rebuilds on changes

Site should be accessible at http://localhost:8000/

### Running the download pipeline

To download fresh data or in case you made changes to the download pipeline:

```
./upv.sh download
```

## Deployment

`data/`, `dist/` and `datapackage.json` are committed to Git, site is served from `dist/` directory on GitHub pages

Travis is used to download, build and commit on push to master.

Site is available at http://orihoch.uumpa.com/calendar-web-app/dist/

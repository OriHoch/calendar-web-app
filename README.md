# calendar-web-app
Static HTML web app that allows to show calendar appointments from verstaile input data sources (using Datapackage Pipelines ETL framework)

## Prerequisites

* Docker

## Usage

Start a local dev server, watch and rebuild on changes
* `./upv.sh . start`
* Site should be accessible at http://localhost:8000/

Re-download the source data
* Source data is committed to Git, you should run this if you want to update it:
  * `./upv.sh . dpp "run ./download"

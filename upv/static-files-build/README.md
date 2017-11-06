# Development and build flow for static files / assets
Provides a simple flow, suitable for local development of static assets using build, watch and http serving.

## Integration

You should define the following aliases in your upv.yaml:

```
aliases:
  # build the web-app (static html files)
  # runs on every push to master by travis
  build: upv upv/static-files-build build

  # start development server + watch + (re)build
  start: upv upv/static-files-build start

  # start a local web server for dist/ directory
  serve: upv upv/static-files-build serve
```

## Usage

Start a local http serve, watch files and rebuild on changes.

```
./upv.sh start
```

The app specific functionality is defined in `functions.sh` in functions named with `static_files_` prefix

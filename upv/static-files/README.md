# Upv framework services for static files / assets build pipeline
Provides a simple flow, suitable for local development of static assets using build, watch and http serving.

## Usage

### Start

Start a local http serve, watch files and rebuild on changes.

Calls `static_files_watch_changes` function in root project `functions.sh`.

```
./upv.sh upv/static-files start
```

### Build

Build static assets and store in the container filesystem.

Calls `static_files_build` function in root project `functions.sh`.

```
./upv.sh upv/static-files build
```

### Serve

Serve the static assets (e.g. using an http server)

Calls `serve_preflight` and `serve_start` in root project `functions.sh`.

```
./upv.sh upv/static-files serve
```

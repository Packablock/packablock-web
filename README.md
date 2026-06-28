# Packablock Web Frontend

A Rails application serving as the web frontend for Packablock.

## Running the Development Stack

The development stack is run via Docker Compose:

```bash
docker compose up -d
```

The server binds to port `3002`.

## ⚠️ Troubleshooting: Restart Loop / Bundler GemNotFound

### The Problem
If the container goes into a restart loop with logs showing:
```
bundler: failed to load command: rails (/usr/local/bundle/bin/rails)
Could not find <gem-name> in locally installed gems (Bundler::GemNotFound)
```

### Root Cause
The `docker-compose.yml` mounts the host directory `.` to `/rails` in the container. If you update `Gemfile` or `Gemfile.lock` on the host, the container sees the updated lockfile but the compiled container image does not contain the newly added gems. This mismatch causes Bundler to crash on startup.

### Resolution
Rebuild the development Docker image to cache the updated dependencies, then restart the service:

```bash
docker compose build
docker compose up -d
```

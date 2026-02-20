# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Builds a minimal Alpine Linux Docker image (`photostructure/base-tools`) that compiles and bundles native dependencies for PhotoStructure for Docker:

- **LibRaw** (image processing for raw camera files) — compiled from source, installed to `/opt/photostructure/tools`
- **SQLite 3** — compiled without readline, stripped binary installed to `/opt/photostructure/tools`

The final image is published to Docker Hub (`photostructure/base-tools`) and GHCR (`ghcr.io/photostructure/base-tools`) for both `linux/amd64` and `linux/arm64`.

## Common Tasks

```sh
make validate      # build the builder stage locally to verify LibRaw + SQLite compile
make update-pins   # update GitHub Actions SHAs in the workflow via `pinact`
```

## CI/CD

Pushes to `main` trigger `.github/workflows/docker-build.yml`, which builds amd64 and arm64 images in parallel (on native runners), then merges them into a multi-arch manifest and pushes to Docker Hub and GHCR.

## Key Constraints

- **Always pin LibRaw by commit SHA**, not tag name. Tags can be force-pushed; SHAs cannot. The user explicitly prefers the SHA even when a named tag is available. Use the GitHub REST API tarball endpoint:
  ```
  https://api.github.com/repos/LibRaw/LibRaw/tarball/<SHA>
  ```

- **Node.js version is intentionally unpinned** (`node:24-alpine`, not `node:24.x-alpine`). Native modules use N-API (ABI-stable), so floating on the minor version allows automatic security patches without breaking builds.

- **No package.json or Node.js app code** — this repo is purely infrastructure (Dockerfile + CI config).

## Architecture

The Dockerfile uses a single build stage (`AS builder`) on `node:24-alpine`:

1. `apk add` build dependencies (autoconf, automake, lcms2-dev, libjpeg-turbo-dev, orc-dev, zlib-dev, util-linux-dev, etc.)
2. Download LibRaw via GitHub REST API tarball (by commit SHA), build with `./configure --prefix=/opt/photostructure/tools && make`
3. Remove everything from the LibRaw install except `libraw.so`, `dcraw_emu`, and `raw-identify`
4. Download SQLite autoconf tarball from sqlite.org, build with `--disable-readline`, strip and copy to `/opt/photostructure/tools`
5. Strip all binaries in `/opt/photostructure/tools`

Output artifacts live at `/opt/photostructure/tools/` and are consumed by downstream PhotoStructure Docker images.

**Note:** Unlike `base-tools-debian`, this image does NOT build jpegtran from source. Alpine's `libjpeg-turbo-progs` package (installed at runtime by the downstream server Dockerfile) provides jpegtran. The Debian variant builds a static jpegtran because it also supplies binaries for Desktop/Node editions via `photostructure/tools/Dockerfile`.

## Updating Dependencies

When bumping LibRaw:
1. `git pull` in `../LibRaw` and review `git log <old-sha>..<new-sha> --oneline` and `git diff --stat`
2. Update the tarball URL in the `Dockerfile` to use the new SHA (not a tag)

When bumping SQLite:
- Update the version number and year segment in the URL (e.g., `/2026/sqlite-autoconf-3XXXXXX.tar.gz`)
- Run `make validate` to confirm it compiles cleanly

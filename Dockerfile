# syntax=docker/dockerfile:1

# Howdy, need help? See
# https://photostructure.com/server/photostructure-for-docker/ and
# https://forum.photostructure.com/

# See https://hub.docker.com/_/node/
# We use node:24 (not node:24.x) because native modules use N-API which is
# ABI-stable across Node versions. This allows automatic security patches.
FROM node:24-alpine AS builder

# https://docs.docker.com/develop/develop-images/multistage-build/

# Build requirements for native node libraries:
# sharp needs lcms2, libjpeg, and liborc

# `npm install --location=global npm` avoids npm warnings about being out of date.

# 202208: we have to build libraw, as the version from github has a bunch of
# bugfixes from the official released version available to Alpine's `apk add`.

# 20250315: instead of git, we're using GitHub REST API to download a specific
# commit of LibRaw. See
# https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives
# and
# https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#download-a-repository-archive-tar

RUN apk update ; apk upgrade ; apk add --no-cache \
  autoconf \
  automake \
  bash \
  build-base \
  ca-certificates \
  coreutils \
  curl \
  lcms2-dev \
  libjpeg-turbo-dev \
  libtool \
  orc-dev \
  pkgconf \
  python3-dev \
  util-linux-dev \
  zlib-dev \
  && npm install --force --location=global npm yarn \
  && mkdir -p /opt/photostructure/tools \
  && mkdir -p /tmp/libraw \
  && cd /tmp/libraw \
  && curl -L https://api.github.com/repos/LibRaw/LibRaw/tarball/f74ddd995c5447458f132a5377ca0f4b394dff6e | tar -xz --strip 1 \
  && autoreconf -fiv \
  && ./configure --prefix=/tmp/libraw/install \
  && make -j `nproc` \
  && make install \
  && cp -p /tmp/libraw/install/bin/dcraw_emu /tmp/libraw/install/bin/raw-identify /opt/photostructure/tools/ \
  && cp -p /tmp/libraw/install/lib/libraw.so* /opt/photostructure/tools/ \
  && rm -rf /tmp/libraw \
  && mkdir -p /tmp/sqlite \
  && cd /tmp/sqlite \
  && curl https://sqlite.org/2026/sqlite-autoconf-3530000.tar.gz | tar -xz --strip 1 \
  && ./configure --disable-readline \
  && make -j `nproc` \
  && strip sqlite3 \
  && cp -p sqlite3 /opt/photostructure/tools/ \
  && rm -rf /tmp/sqlite \
  && strip /opt/photostructure/tools/*

# Note: static binaries would be a bit more portable, but installing
# libjpeg isn't that big of a deal.

# Stripped LibRaw and SQLite binaries should now be sitting in
# /opt/photostructure/tools/.

# docker build -t photostructure/base-tools .

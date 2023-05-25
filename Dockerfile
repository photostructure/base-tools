# syntax=docker/dockerfile:1

# Howdy, need help? See
# <https://photostructure.com/server/photostructure-for-docker/> and
# <https://forum.photostructure.com/>

# See https://hub.docker.com/_/node/
# This will be equivalent to "lts-alpine" later in 2023:
FROM node:20-alpine3.17 as builder

# https://docs.docker.com/develop/develop-images/multistage-build/

# Build requirements for native node libraries:
# sharp needs lcms2, libjpeg, and liborc

# `npm install --location=global npm` avoids npm warnings about being out of date.

# 202208: we have to build libraw, as the version from github has a bunch of
# bugfixes from the official released version available to Alpine's `apk add`.

RUN apk update ; apk upgrade ; apk add --no-cache \
  autoconf \
  automake \
  bash \
  build-base \
  ca-certificates \
  coreutils \
  curl \
  git \
  lcms2-dev \
  libjpeg-turbo-dev \
  libtool \
  orc-dev \
  pkgconf \
  python3-dev \
  zlib-dev \
  && npm install --force --location=global npm yarn \
  && mkdir -p /opt/photostructure/tools \
  && git clone https://github.com/LibRaw/LibRaw.git /tmp/libraw \
  && cd /tmp/libraw \
  && git checkout --force 6fffd414bfda63dfef2276ae07f7ca36660b8888 \
  && autoreconf -fiv \
  && ./configure --prefix=/opt/photostructure/tools \
  && make -j `nproc` \
  && make install \
  && rm $(find /opt/photostructure/tools -type f | grep -vE "libraw.so|dcraw_emu|raw-identify") \
  && rmdir -p --ignore-fail-on-non-empty $(find /opt/photostructure/tools -type d) \ 
  && strip /opt/photostructure/tools/bin/* \
  && rm -rf /tmp/libraw \
  && mkdir -p /tmp/sqlite \
  && cd /tmp/sqlite \
  && curl https://sqlite.org/2023/sqlite-autoconf-3420000.tar.gz | tar -xz --strip 1 \
  && ./configure --disable-readline \
  && make -j `nproc` \
  && strip sqlite3 \
  && cp -p sqlite3 /opt/photostructure/tools/bin \
  && rm -rf /tmp/sqlite

# Note: static binaries would be a bit more portable, but installing
# libjpeg isn't that big of a deal.

# Stripped LibRaw and SQLite binaries should now be sitting in
# /opt/photostructure/tools/bin.

# docker build -t photostructure/base-tools .

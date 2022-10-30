# syntax=docker/dockerfile:1

# Howdy, need help? See
# <https://photostructure.com/server/photostructure-for-docker/> and
# <https://forum.photostructure.com/>

# See https://hub.docker.com/_/node/
FROM node:lts-alpine as builder

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
  git \
  lcms2-dev \
  libjpeg-turbo-dev \
  libtool \
  orc-dev \
  pkgconf \
  python3-dev \
  zlib-dev && \
  npm install --force --location=global npm yarn && \
  mkdir -p /ps/app/tools && \
  git clone https://github.com/LibRaw/LibRaw.git /tmp/libraw && \
  cd /tmp/libraw && \
  git checkout --force a5a5fb16936f0d3da0ea2ee92e43f508921c121a && \
  autoreconf -fiv && \
  ./configure --prefix=/ps/app/tools && \
  make -j8 && \
  make install && \
  rm $(find /ps/app/tools -type f | grep -vE "libraw.so|dcraw_emu|raw-identify") && \
  rmdir -p --ignore-fail-on-non-empty $(find /ps/app/tools -type d) && \ 
  strip /ps/app/tools/bin/* && \
  rm -rf /tmp/libraw

# Stripped LibRaw binaries should now be sitting in /ps/app/tools/bin.

# TODO: support watchman? This tag fails to build boost:
# RUN git clone https://github.com/facebook/watchman.git -b v2022.05.16.00 --depth 1 /tmp/watchman-src && \
#   cd /tmp/watchman-src && \
#   ./autogen.sh && \
#   ./configure --enable-statedir=/tmp --enable-lenient --without-python --without-pcre --prefix=/ps/app/tools && \
#   make && \

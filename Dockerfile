# syntax=docker/dockerfile:1

# Howdy, need help? See
# <https://photostructure.com/server/photostructure-for-docker/> and
# <https://forum.photostructure.com/>

# See https://hub.docker.com/_/node/
FROM node:lts-alpine as builder

# https://docs.docker.com/develop/develop-images/multistage-build/

# Build requirements for native node libraries:
# sharp needs lcms2, libjpeg, and liborc

RUN apk update ; apk upgrade ; apk add --no-cache \
  autoconf \
  automake \
  bash \
  build-base \
  coreutils \
  git \
  lcms2-dev \
  libjpeg-turbo-dev \
  libtool \
  orc-dev \
  pkgconf \
  python3-dev \
  zlib-dev 

# We have to build libraw: the version from github has a bunch of bugfixes from
# the official released version available to Alpine's `apk add`.

RUN mkdir -p /ps/app/tools && \
  git clone https://github.com/LibRaw/LibRaw.git && \
  cd LibRaw && \
  git checkout --force adcb898a00746c8aa886eb06cc9f5a1cb1834fca && \
  autoreconf -fiv && \
  ./configure --prefix=/ps/app/tools && \
  make -j24 && \
  make install && \
  rm $(find /ps/app/tools -type f | grep -vE "libraw.so|dcraw_emu|raw-identify") && \
  rmdir -p --ignore-fail-on-non-empty $(find /ps/app/tools -type d) && \ 
  strip /ps/app/tools/bin/* && \
  rm -rf /tmp/LibRaw

# Stripped LibRaw binaries should now be sitting in /ps/app/tools/bin.

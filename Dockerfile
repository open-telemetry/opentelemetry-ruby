# Configuration for Ruby base image
ARG ALPINE_VERSION=3.13
ARG RUBY_VERSION=3.0.0

FROM ruby:"${RUBY_VERSION}-alpine${ALPINE_VERSION}" as ruby

# Metadata
LABEL maintainer="open-telemetry/opentelemetry-ruby"

# User and Group for app isolation
ARG APP_UID=1000
ARG APP_USER=app
ARG APP_GID=1000
ARG APP_GROUP=app
ARG APP_DIR=/app

# Rubygems Bundler version
ARG BUNDLER_VERSION=2.0.2

ENV SHELL /bin/bash

ARG PACKAGES="\
    autoconf \
    automake \
    bash \
    binutils \
    build-base \
    coreutils  \
    execline \
    findutils \
    git \
    grep \
    less \
    libstdc++ \
    libtool \
    libxml2-dev \
    libxslt-dev \
    mariadb-dev \
    openssl \
    postgresql-dev \
    tzdata \
    util-linux \
    "
# Install packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${PACKAGES}

# Configure Bundler and PATH
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=20 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG="${BUNDLE_PATH}" \
    BUNDLE_BIN="${BUNDLE_PATH}/bin" \
    BUNDLE_GEMFILE=Gemfile
ENV PATH "${APP_DIR}/bin:${BUNDLE_BIN}:${PATH}"

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install "bundler:${BUNDLER_VERSION}" && \
    gem cleanup

# Add custom app User and Group
RUN addgroup -S -g "${APP_GID}" "${APP_GROUP}" && \
    adduser -S -g "${APP_GROUP}" -u "${APP_UID}" "${APP_USER}"

# Create directories for the app code
RUN mkdir -p "${APP_DIR}" \
    "${APP_DIR}/tmp" && \
    chown -R "${APP_USER}":"${APP_GROUP}" "${APP_DIR}" \
    "${APP_DIR}/tmp" \
    "${BUNDLE_PATH}/"

USER "${APP_USER}"

WORKDIR "${APP_DIR}"

# Commands will be supplied via `docker-compose`
CMD []

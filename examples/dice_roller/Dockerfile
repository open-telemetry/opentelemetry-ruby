
# syntax=docker/dockerfile:1

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# ---------------------------------------------------------------------------
# Build argument: set to "instrumented" (default) or "uninstrumented"
# ---------------------------------------------------------------------------
ARG APP_VERSION=instrumented

FROM ruby:3.3-slim AS base

WORKDIR /app

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Uninstrumented stage
# ---------------------------------------------------------------------------
FROM base AS uninstrumented

COPY uninstrumented/Gemfile ./Gemfile
RUN bundle install

COPY uninstrumented/app.rb  ./app.rb
COPY uninstrumented/dice.rb ./dice.rb

ENV APPLICATION_PORT=8080
EXPOSE 8080

CMD ["ruby", "app.rb"]

# ---------------------------------------------------------------------------
# Instrumented stage
# ---------------------------------------------------------------------------
FROM base AS instrumented

COPY instrumented/Gemfile ./Gemfile
RUN bundle install

COPY instrumented/otel.rb  ./otel.rb
COPY instrumented/dice.rb  ./dice.rb
COPY instrumented/app.rb   ./app.rb

ENV APPLICATION_PORT=8080
# Service name used by OTel SDK (can be overridden at runtime)
ENV OTEL_SERVICE_NAME=dice_roller
# Export to console by default; override with "otlp" to send to a collector
ENV OTEL_TRACES_EXPORTER=console
ENV OTEL_METRICS_EXPORTER=console
ENV OTEL_LOGS_EXPORTER=console

EXPOSE 8080

CMD ["ruby", "app.rb"]
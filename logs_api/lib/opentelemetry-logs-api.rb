# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/logs'
require 'opentelemetry/logs/version'
require 'opentelemetry/internal/proxy_logger_provider'
require 'opentelemetry/internal/proxy_logger'
require 'opentelemetry/internal/global_logger_provider'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# Requiring this gem makes the Logs API available to instrumentation through
# {OpenTelemetry::Internal.logger_provider}.

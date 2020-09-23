# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentation-concurrent_ruby'
require 'opentelemetry-instrumentation-ethon'
require 'opentelemetry-instrumentation-excon'
require 'opentelemetry-instrumentation-faraday'
require 'opentelemetry-instrumentation-mysql2'
require 'opentelemetry-instrumentation-net_http'
require 'opentelemetry-instrumentation-rack'
require 'opentelemetry-instrumentation-redis'
require 'opentelemetry-instrumentation-restclient'
require 'opentelemetry-instrumentation-sidekiq'
require 'opentelemetry-instrumentation-sinatra'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  module Instrumentation
    # Namespace for the Opentelemetry all-in-one gem
    module All
    end
  end
end

require_relative './all/version'

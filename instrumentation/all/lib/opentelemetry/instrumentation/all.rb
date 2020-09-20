# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentation-concurrent_ruby'
require 'opentelemetry-instrumentation-ethon'
require 'opentelemetry-instrumentation-excon'
require 'opentelemetry-instrumentation-graphql'
require 'opentelemetry-instrumentation-faraday'
require 'opentelemetry-instrumentation-mysql2'
require 'opentelemetry-instrumentation-net_http'
require 'opentelemetry-instrumentation-rack'
require 'opentelemetry-instrumentation-redis'
require 'opentelemetry-instrumentation-restclient'
require 'opentelemetry-instrumentation-sidekiq'
require 'opentelemetry-instrumentation-sinatra'

module OpenTelemetry
  module Instrumentation
    # Namespace for the Opentelemetry all-in-one gem
    module All
    end
  end
end

require_relative './all/version'

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentations-concurrent_ruby'
require 'opentelemetry-instrumentations-ethon'
require 'opentelemetry-instrumentations-excon'
require 'opentelemetry-instrumentations-faraday'
require 'opentelemetry-instrumentations-net_http'
require 'opentelemetry-instrumentations-rack'
require 'opentelemetry-instrumentations-redis'
require 'opentelemetry-instrumentations-restclient'
require 'opentelemetry-instrumentations-sidekiq'
require 'opentelemetry-instrumentations-sinatra'

module OpenTelemetry
  module Instrumentations
    # Namespace for the Opentelemetry all-in-one gem
    module All
    end
  end
end

require_relative './all/version'

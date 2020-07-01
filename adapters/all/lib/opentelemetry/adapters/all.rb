# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-adapters-concurrent_ruby'
require 'opentelemetry-adapters-ethon'
require 'opentelemetry-adapters-excon'
require 'opentelemetry-adapters-faraday'
require 'opentelemetry-adapters-mysql2'
require 'opentelemetry-adapters-net_http'
require 'opentelemetry-adapters-rack'
require 'opentelemetry-adapters-redis'
require 'opentelemetry-adapters-restclient'
require 'opentelemetry-adapters-sidekiq'
require 'opentelemetry-adapters-sinatra'

module OpenTelemetry
  module Adapters
    # Namespace for the Opentelemetry all-in-one gem
    module All
    end
  end
end

require_relative './all/version'

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-adapters-concurrent-ruby'
require 'opentelemetry-adapters-ethon'
require 'opentelemetry-adapters-excon'
require 'opentelemetry-adapters-faraday'
require 'opentelemetry-adapters-net-http'
require 'opentelemetry-adapters-rack'
require 'opentelemetry-adapters-redis'
require 'opentelemetry-adapters-rest-client'
require 'opentelemetry-adapters-sinatra'

module OpenTelemetry
  module Adapters
    # Namespace for the Opentelemetry all-in-one gem
    module All
    end
  end
end

require_relative './all/version'

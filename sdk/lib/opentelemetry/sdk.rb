# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  # SDK provides the reference implementation of the OpenTelemetry API.
  module SDK
    extend self

    # Configures SDK and instrumentation
    #
    # @yieldparam [Configurator] configurator Yields a configurator to the
    #   provided block
    #
    def configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    end
  end
end

require 'opentelemetry/sdk/configurator'
require 'opentelemetry/sdk/internal'
require 'opentelemetry/sdk/resources'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/version'

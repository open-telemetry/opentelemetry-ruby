# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # SDK provides the reference implementation of the OpenTelemetry API.
  module SDK
    extend self

    # Configures SDK and instrumentation
    #
    # @yieldparam [Configurator] configurator Yields a configurator to the
    #   provided block
    #
    # Example usage:
    #   Without a block defaults are installed without any instrumentation
    #
    #     OpenTelemetry::SDK.configure
    #
    #   Install instrumentation individually with optional config
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.use 'OpenTelemetry::Instrumentation::Faraday', tracer_middleware: SomeMiddleware
    #     end
    #
    #   Install all instrumentation with optional config
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.use_all 'OpenTelemetry::Instrumentation::Faraday' => { tracer_middleware: SomeMiddleware }
    #     end
    #
    #   Add a span processor
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.add_span_processor SpanProcessor.new(SomeExporter.new)
    #     end
    #
    #   Configure everything
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.logger = Logger.new('/dev/null')
    #       c.add_span_processor SpanProcessor.new(SomeExporter.new)
    #       c.use_all
    #     end
    def configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    end
  end
end

require 'opentelemetry/sdk/configurator'
require 'opentelemetry/sdk/baggage'
require 'opentelemetry/sdk/internal'
require 'opentelemetry/sdk/instrumentation_library'
require 'opentelemetry/sdk/resources'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/version'

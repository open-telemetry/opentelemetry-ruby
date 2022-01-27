# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-metrics-api'

module OpenTelemetry
  # MetricsSDK provides the reference implementation of the OpenTelemetry Metrics API.
  module MetricsSDK
    extend self

    ConfigurationError = Class.new(OpenTelemetry::Error)

    def configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    rescue StandardError
      begin
        raise ConfigurationError
      rescue ConfigurationError => e
        OpenTelemetry.handle_error(exception: e, message: "unexpected configuration error due to #{e.cause}")
      end
    end
  end
end

require 'opentelemetry/metrics_sdk/configurator'
require 'opentelemetry/metrics_sdk/instrumentation_library'
require 'opentelemetry/metrics_sdk/metrics'

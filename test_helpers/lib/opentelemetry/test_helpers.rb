# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

module OpenTelemetry
  module TestHelpers
    extend self
    NULL_LOGGER = Logger.new(File::NULL)

    # reset_opentelemetry is a test helper used to clear
    # SDK configuration state between calls
    def reset_opentelemetry
      OpenTelemetry.instance_variable_set(
        :@tracer_provider,
        OpenTelemetry::Internal::ProxyTracerProvider.new
      )

      # OpenTelemetry will load the defaults
      # on the next call to any of these methods
      OpenTelemetry.error_handler = nil
      OpenTelemetry.propagation = nil

      # We use a null logger to control the console
      # log output and explicitly enable it
      # when testing the log output
      OpenTelemetry.logger = NULL_LOGGER
    end

    def with_test_logger
      log_stream = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)
      yield log_stream
    ensure
      OpenTelemetry.logger = original_logger
    end

    def exportable_timestamp(time = Time.now)
      (time.to_r * 1_000_000_000).to_i
    end

    def with_env(new_env)
      env_to_reset = ENV.select { |k, _| new_env.key?(k) }
      keys_to_delete = new_env.keys - ENV.keys
      new_env.each_pair { |k, v| ENV[k] = v }
      yield
    ensure
      env_to_reset.each_pair { |k, v| ENV[k] = v }
      keys_to_delete.each { |k| ENV.delete(k) }
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Logs
    # No-op implementation of a logger provider.
    class LoggerProvider
      NOOP_LOGGER = OpenTelemetry::Logs::Logger.new
      private_constant :NOOP_LOGGER

      # Returns an {OpenTelemetry::Logs::Logger} instance.
      #
      # @param [String] name Instrumentation scope name
      # @param [optional String] version Instrumentation scope version
      #
      # @return [OpenTelemetry::Logs::Logger]
      def logger(name:, version: nil)
        @logger ||= NOOP_LOGGER
      end
    end
  end
end

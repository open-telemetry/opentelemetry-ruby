# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # The SDK implementation of OpenTelemetry::Logs::Logger
      class Logger < OpenTelemetry::Logs::Logger
        # @api private
        #
        # Returns a new {OpenTelemetry::SDK::Logs::Logger} instance. This should
        # not be called directly. New loggers should be created using
        # {LoggerProvider#logger}.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [LoggerProvider] logger_provider The {LoggerProvider} that
        #   initialized the logger
        #
        # @return [OpenTelemetry::SDK::Logs::Logger]
        def initialize(name, version, logger_provider)
          @instrumentation_scope = InstrumentationScope.new(name, version)
          @logger_provider = logger_provider
        end
      end
    end
  end
end

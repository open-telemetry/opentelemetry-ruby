# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require_relative 'opentelemetry/logs'
require_relative 'opentelemetry/logs/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
module OpenTelemetry
  # Register the global logger provider.
  #
  # @param [LoggerProvider] provider A logger provider to register as the
  #   global instance.
  def logger_provider=(provider)
    puts 'nil logger provider' if provider.nil?
    @logger_provider = provider
  end

  # @return [Object, Logs::LoggerProvider] registered logger provider or a
  #   default no-op implementation of the logger provider.
  def logger_provider
    @mutex.synchronize { @logger_provider }
  end
end

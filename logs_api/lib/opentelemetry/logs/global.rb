# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-logs-api'

# Defines the top-level accessors for the global logger provider. The Logs
# API is unstable, so requiring +opentelemetry-logs-api+ does not define
# these. Requiring +opentelemetry-logs-sdk+ does.
#
# These are delegators. The provider itself lives in
# {OpenTelemetry::Internal}, so this file can be required at any point,
# before or after the SDK is configured.
module OpenTelemetry
  # Register the global logger provider.
  #
  # @param [LoggerProvider] provider A logger provider to register as the
  #   global instance.
  def logger_provider=(provider)
    Internal.logger_provider = provider
  end

  # @return [Object, Logs::LoggerProvider] registered logger provider or a
  #   default no-op implementation of the logger provider.
  def logger_provider
    Internal.logger_provider
  end
end

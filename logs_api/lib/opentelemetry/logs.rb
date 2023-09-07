# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'logs/log_record'
require_relative 'logs/logger'
require_relative 'logs/logger_provider'

module OpenTelemetry
  # The Logs API records a timestamped record with metadata.
  # In OpenTelemetry, any data that is not part of a distributed trace or a
  # metric is a log. For example, events are a specific type of log.
  #
  # This API is provided for logging library authors to build log
  # appenders/bridges. It should NOT be used directly by application
  # developers.
  module Logs
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # The Export module contains the built-in exporters and log record
      # processors for the OpenTelemetry reference implementation.
      module Export
        ExportError = Class.new(OpenTelemetry::Error)
        # The operation finished successfully.
        SUCCESS = 0

        # The operation finished with an error.
        FAILURE = 1

        # The operation timed out.
        TIMEOUT = 2
      end
    end
  end
end

require_relative 'export/log_record_exporter'

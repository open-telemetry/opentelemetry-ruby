# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      # The Export module contains the built-in exporters and log processors for the OpenTelemetry reference implementation.
      module Export
        # Result codes for the LogExporter#export method and the LogProcessor#force_flush and LogProcessor#shutdown methods.

        # The operation finished successfully.
        SUCCESS = 0

        # The operation finished with an error.
        FAILURE = 1

        # Additional result code for the LogProcessor#force_flush and LogProcessor#shutdown methods.

        # The operation timed out.
        TIMEOUT = 2
      end
    end
  end
end

require 'opentelemetry/sdk/log/export/batch_log_processor'
require 'opentelemetry/sdk/log/export/simple_log_processor'
require 'opentelemetry/sdk/log/export/console_log_exporter'
require 'opentelemetry/sdk/log/export/in_memory_log_exporter'
require 'opentelemetry/sdk/log/export/metrics_reporter'
require 'opentelemetry/sdk/log/export/multi_log_exporter'
require 'opentelemetry/sdk/log/export/noop_log_exporter'

# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # The Export module contains the built-in exporters for the OpenTelemetry
      # reference implementation.
      module Export
        # Result codes for the SpanExporter#export method.

        # The export operation finished successfully.
        SUCCESS = 0

        # The export operation finished with an error, but retrying may
        # succeed.
        FAILED_RETRYABLE = 1

        # The export operation finished with an error, the caller should not
        # try to export the same data again.
        FAILED_NOT_RETRYABLE = 2
      end
    end
  end
end

require 'opentelemetry/sdk/trace/export/batch_sampled_span_processor'
require 'opentelemetry/sdk/trace/export/in_memory_span_exporter'
require 'opentelemetry/sdk/trace/export/multi_span_exporter'
require 'opentelemetry/sdk/trace/export/noop_span_exporter'
require 'opentelemetry/sdk/trace/export/simple_sampled_span_processor'

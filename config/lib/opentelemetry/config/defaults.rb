# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Config
    # Schema defaults for omitted or null properties. Keys use schema names;
    # durations are in milliseconds and are converted by the builders.
    module Defaults
      BATCH_SPAN_PROCESSOR = {
        schedule_delay: 5_000,
        export_timeout: 30_000,
        max_queue_size: 2048,
        max_export_batch_size: 512
      }.freeze

      SPAN_LIMITS = {
        attribute_count_limit: 128,
        attribute_value_length_limit: nil,
        event_count_limit: 128,
        link_count_limit: 128,
        event_attribute_count_limit: 128,
        link_attribute_count_limit: 128
      }.freeze

      OTLP_HTTP_EXPORTER = {
        compression: 'none',
        timeout: 10_000
      }.freeze

      OTLP_HTTP_TRACES_ENDPOINT = 'http://localhost:4318/v1/traces'
    end

    private_constant :Defaults
  end
end

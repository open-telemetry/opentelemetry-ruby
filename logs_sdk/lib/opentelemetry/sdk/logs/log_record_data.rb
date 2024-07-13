# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # LogRecordData is a Struct containing {LogRecord} data for export.
      LogRecordData = Struct.new(:timestamp,             # optional Integer nanoseconds since Epoch
                                 :observed_timestamp,    # Integer nanoseconds since Epoch
                                 :severity_text,         # optional String
                                 :severity_number,       # optional Integer
                                 :body,                  # optional String, Numeric, Boolean, Array<String, Numeric,
                                 #   Boolean>, Hash{String => String, Numeric, Boolean,
                                 #   Array<String, Numeric, Boolean>}
                                 :attributes, # optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}
                                 :trace_id,              # optional String (16-byte binary)
                                 :span_id,               # optional String (8-byte binary)
                                 :trace_flags,           # optional Integer (8-bit byte of bit flags)
                                 :resource,              # optional OpenTelemetry::SDK::Resources::Resource
                                 :instrumentation_scope, # OpenTelemetry::SDK::InstrumentationScope
                                 :total_recorded_attributes) do # Integer
        def unix_nano_timestamp
          return unless timestamp.is_a?(Time)

          (timestamp.to_r * 10**9).to_i
        end

        def unix_nano_observed_timestamp
          return unless observed_timestamp.is_a?(Time)

          (observed_timestamp.to_r * 10**9).to_i
        end
      end
    end
  end
end

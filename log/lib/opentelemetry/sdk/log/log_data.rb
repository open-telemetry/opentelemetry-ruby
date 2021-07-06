# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Log module contains the OpenTelemetry log reference implementation.
    module Log
      # LogData is a Struct containing {LogRecord} data for export.
      LogData = Struct.new(:timestamp,               # Integer nanoseconds since Epoch
                           :trace_id,                # optional String (16-byte binary)
                           :span_id,                 # optional String (8-byte binary)
                           :trace_flags,             # optional Integer (8-bit byte of bit flags)
                           :severity_text,           # optional String
                           :severity_number,         # optional Integer
                           :name,                    # optional String
                           :body,                    # optional any
                           :attributes,              # optional Hash{String => any}
                           :resource,                # optional OpenTelemetry::SDK::Resources::Resource
                           :instrumentation_library) # OpenTelemetry::SDK::InstrumentationLibrary
    end
  end
end

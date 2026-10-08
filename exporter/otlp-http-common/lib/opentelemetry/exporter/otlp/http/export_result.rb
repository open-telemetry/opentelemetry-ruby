# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # ExportResult is a struct class for representing the result of an export operation in the OTLP HTTP exporter.
        ExportResult = Struct.new(
          :success,
          :http_response_code,
          :http_response_body,
          keyword_init: true
        )
      end
    end
  end
end

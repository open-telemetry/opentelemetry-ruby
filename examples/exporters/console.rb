# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'pp'

module Examples
  module Exporters
    # Outputs span data to the console.
    class Console
      include OpenTelemetry::SDK::Trace::Export

      def export(spans)
        Array(spans).each { |s| pp s }

        SUCCESS
      end
    end
  end
end

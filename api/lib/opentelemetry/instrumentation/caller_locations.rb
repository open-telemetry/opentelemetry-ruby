# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The instrumentation CallerLocations contains a reusable function to add caller information to instrumentations
    class CallerLocations
      def self.detect_caller_location
        if ENV['OTEL_EXPORTER_ADD_CALLER_LOCATION']
          cleaned_up_trace = caller_locations.delete_if { |loc| loc.absolute_path.match('/.rvm/gems/') }
          non_gem_first_line = cleaned_up_trace.last
          {
            'code.lineno' => non_gem_first_line.lineno,
            'code.filepath' => non_gem_first_line.absolute_path,
            'code.function' => non_gem_first_line.base_label
          }
        else
          {}
        end
      end
    end
  end
end

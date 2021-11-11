# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Rails
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        # This gem requires the instrumentantion gems for the different
        # components of Rails, as a result it does not have any explicit
        # work to do in the install step.
        install { true }
        present { defined?(::Rails) }

        private

        def gem_name
          'actionpack'
        end

        def minimum_version
          '5.2.0'
        end
      end
    end
  end
end

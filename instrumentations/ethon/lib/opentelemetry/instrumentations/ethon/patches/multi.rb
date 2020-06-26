# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentations
    module Ethon
      module Patches
        # Ethon::Multi patch for instrumentation
        module Multi
          def perform
            easy_handles.each do |easy|
              easy.otel_before_request unless easy.otel_span_started?
            end

            super
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Patches
        # The Processor module contains the insturmentation for the process_one method
        module Processor
          private

          def process_one
            if config[:trace_processor_process_one]
              tracer.in_span('Sidekiq::Processor#process_one') { super }
            else
              untraced { super }
            end
          end

          def tracer
            Sidekiq::Instrumentation.instance.tracer
          end

          def config
            Sidekiq::Instrumentation.instance.config
          end

          def untraced
            OpenTelemetry::Trace.with_span(OpenTelemetry::Trace::Span.new) { yield }
          end
        end
      end
    end
  end
end

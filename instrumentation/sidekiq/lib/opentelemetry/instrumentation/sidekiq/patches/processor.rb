# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Patches
        # The Processor module contains the instrumentation for the process_one method
        module Processor
          private

          def process_one
            if config[:trace_processor_process_one]
              attributes = {}
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]
              tracer.in_span('Sidekiq::Processor#process_one', attributes: attributes) { super }
            else
              OpenTelemetry::Common::Utilities.untraced { super }
            end
          end

          def tracer
            Sidekiq::Instrumentation.instance.tracer
          end

          def config
            Sidekiq::Instrumentation.instance.config
          end
        end
      end
    end
  end
end

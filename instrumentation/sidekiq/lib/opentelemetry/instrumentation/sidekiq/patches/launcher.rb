# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Patches
        module Launcher
          def ❤
            if config[:trace_launcher_heartbeat]
              tracer.in_span('Sidekiq::Launcher#heartbeat') { super }
            else
              untraced { super }
            end
          end

          private

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

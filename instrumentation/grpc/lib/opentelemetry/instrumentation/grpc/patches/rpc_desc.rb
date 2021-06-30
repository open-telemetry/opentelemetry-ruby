# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      module Patches
        module RpcDesc
          # This is the entry point to all server-side calls.
          def run_server_method(active_call, mth, inter_ctx = ::GRPC::InterceptionContext.new)
            attrs = {
              "rpc.system" => "grpc",
              "rpc.service" => mth.owner.service_name,
              "rpc.method" => mth.name.to_s
            }
            context = OpenTelemetry.propagation.extract(active_call.metadata)
            span = tracer.start_span(
              "#{mth.owner.service_name}/#{mth.name}",
              with_parent: context,
              kind: :server,
              attributes: attrs
            )
            # The server's ActiveCall is created during the accept loop, and so the
            # current_span saved off when created will likely be a non-recording API
            # span. So we replace the saved-off span with whatever we just created.
            active_call.span = span

            OpenTelemetry::Trace.with_span(span) { super }
          end

          private
          def tracer
            GRPC::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end

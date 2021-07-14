# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      module Patches
        # Patches to prepend to ::GRPC::ClientStub.
        module ClientStub
          # Handles the "unary" client call.
          def request_response(method, req, marshal, unmarshal, deadline: nil, return_op: false, parent: nil, credentials: nil, metadata: {})
            OpenTelemetry::Trace.with_span(start_span(method, metadata)) { super }
          end

          # Handles the "client streaming" client call
          def client_streamer(method, requests, marshal, unmarshal, deadline: nil, return_op: false, parent: nil, credentials: nil, metadata: {})
            OpenTelemetry::Trace.with_span(start_span(method, metadata)) { super }
          end

          # Handles the "server streaming" client call
          def server_streamer(method, req, marshal, unmarshal, deadline: nil, return_op: false, parent: nil, credentials: nil, metadata: {}, &blk)
            OpenTelemetry::Trace.with_span(start_span(method, metadata)) { super }
          end

          # Handles the "bi-directional streaming" client call
          def bidi_streamer(method, requests, marshal, unmarshal, deadline: nil, return_op: false, parent: nil, credentials: nil, metadata: {}, &blk)
            OpenTelemetry::Trace.with_span(start_span(method, metadata)) { super }
          end

          private

          def start_span(method, metadata)
            method_parts = method.to_s.sub(%r{^\/}, '').split('/')
            service_name = method_parts.shift
            method_name = method_parts.join('/')
            attrs = {
              'rpc.system' => 'grpc',
              'rpc.service' => service_name.to_s,
              'rpc.method' => method_name.to_s
            }

            span = tracer.start_span(
              "#{service_name}/#{method_name}",
              kind: :client,
              attributes: attrs
            )
            OpenTelemetry.propagation.inject(metadata, context: OpenTelemetry::Trace.context_with_span(span))

            span
          end

          def tracer
            GRPC::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end

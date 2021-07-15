# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      module Patches
        # Patches to prepend to ::GRPC::ActiveCall.
        module ActiveCall
          def initialize(call, marshal, unmarshal, deadline, started: true, metadata_received: false, metadata_to_send: nil)
            super
            @span = OpenTelemetry::Trace.current_span
          end

          # We need a setter because while we can easily capture a correct trace during initialization
          # on the client side, it's a little harder in the accept loop on the server. So, we provide
          # a way for server-side ActiveCalls to set the span after the ActiveCall is created.
          def span=(span)
            @span = span
          end

          # Handles the "unary" client call.
          def request_response(req, metadata: {})
            OpenTelemetry::Trace.with_span(@span) { super }
          end

          # Handles the "client streaming" client call
          def client_streamer(requests, metadata: {})
            OpenTelemetry::Trace.with_span(@span) { super }
          end

          # Handles the "server streaming" client call
          def server_streamer(req, metadata: {})
            OpenTelemetry::Trace.with_span(@span) { super }
          end

          # Handles the "bi-directional streaming" client call
          def bidi_streamer(requests, metadata: {})
            OpenTelemetry::Trace.with_span(@span) { super }
          end

          # There are some instances where the client may receive
          # an enumerator back from a streaming call, and in those cases
          # the actual calls to read from the server are not executed until
          # the client starts calling `next`. So we must ensure our desired
          # span is active here, for those cases.
          def each_remote_read_then_finish
            OpenTelemetry::Trace.with_span(@span) { super }
          end

          # This method is locked with a mutex and only called
          # from set_{input,output}_stream_done. We use it to finish
          # off the span we've been tracking throughout the
          # lifecycle of this ActiveCall.
          def maybe_finish_and_close_call_locked
            super
          ensure
            if @call_finished && @span.recording?
              unless status.nil?
                @span.set_attribute('rpc.grpc.status_code', status.code)
                @span.status = OpenTelemetry::Trace::Status.error unless status.code == ::GRPC::Core::StatusCodes::OK
              end
              @span.finish
            end
          end
        end
      end
    end
  end
end

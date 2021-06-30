# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      module Patches
        module CoreCall
          # This is the heart of sending / receiving GRPC messages on the wire,
          # and it's a C extension. However, we can still intercept it here to
          # handle the log message requirements of the OpenTelemetry semantic conventions.
          def run_batch(ops)
            if ops.keys.include?(::GRPC::Core::CallOps::SEND_MESSAGE)
              OpenTelemetry::Trace.current_span.add_event(
                "message",
                attributes: {
                  "message.type" => "SENT",
                  "message.id" => sent_messages
                }
              )
            end

            result = super

            # We could have a nil result or a batch with a nil message. The precise semantics
            # elude me here, but ActiveCall#get_message_from_batch_result does a similar
            # check when deciding to try and unmarshal the result. Practically speaking, that
            # means if we wouldn't unmarshal the result, we probably didn't "receive" anything
            # insofar as the OpenTelemetry semantic conventions are concerned.
            unless ops.keys.none?(::GRPC::Core::CallOps::RECV_MESSAGE) || result.nil? || result.message.nil?
              OpenTelemetry::Trace.current_span.add_event(
                "message",
                attributes: {
                  "message.type" => "RECEIVED",
                  "message.id" => received_messages
                }
              )
            end

            result
          end

          private
          def sent_messages
            @sent_messages ||= 0
            @sent_messages += 1

            @sent_messages
          end

          def received_messages
            @received_messages ||= 0
            @received_messages += 1

            @received_messages
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GRPC
      module Patches
        module BidiCall
          def initialize(call, marshal, unmarshal, metadata_received: false, req_view: nil)
            super
            @span = OpenTelemetry::Trace.current_span
          end

          # Bi-directional streaming calls handle sending in a background thread.
          # Because of that, we'll need to ensure our desired span is active.
          def write_loop(requests, is_client: true, set_output_stream_done: nil)
            OpenTelemetry::Trace.with_span(@span) { super }
          end
        end
      end
    end
  end
end

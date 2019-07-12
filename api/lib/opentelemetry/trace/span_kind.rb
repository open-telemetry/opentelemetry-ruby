# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Type of span. Can be used to specify additional relationships between spans in addition to a
    # parent/child relationship.
    module SpanKind
      # Default value. Indicates that the span is used internally.
      INTERNAL = :__span_kind_internal__

      # Indicates that the span covers server-side handling of an RPC or other remote request.
      SERVER = :__span_kind_server__

      # Indicates that the span covers the client-side wrapper around an RPC or other remote request.
      CLIENT = :__span_kind_client__

      # Indicates that the span describes producer sending a message to a broker. Unlike client and
      # server, there is no direct critical path latency relationship between producer and consumer
      # spans.
      PRODUCER = :__span_kind_producer__

      # Indicates that the span describes consumer recieving a message from a broker. Unlike client
      # and server, there is no direct critical path latency relationship between producer and
      # consumer spans.
      CONSUMER = :__span_kind_consumer__
    end
  end
end

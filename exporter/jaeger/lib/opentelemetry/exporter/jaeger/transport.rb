# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Jaeger
      # A Thrift-compatible UDP transport.
      class Transport
        def initialize(host, port)
          @socket = UDPSocket.new
          @socket.connect(host, port)
          @buffer = ::Thrift::MemoryBufferTransport.new
        end

        def write(string)
          @buffer.write(string)
        end

        def flush
          @socket.send(@buffer.read(@buffer.available), 0)
          @socket.flush
        rescue Errno::ECONNREFUSED
          OpenTelemetry.logger.warn('Unable to connect to Jaeger Agent')
        rescue StandardError => e
          OpenTelemetry.logger.warn("Unable to send spans: #{e.message}")
        end

        def open; end

        def close; end
      end
    end
  end
end

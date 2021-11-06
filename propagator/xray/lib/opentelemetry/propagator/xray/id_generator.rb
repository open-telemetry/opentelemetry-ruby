# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Propagator
    module XRay
      # This module is intended to only be used as an override for how to generate IDs to be compliant with XRay
      module IDGenerator
        extend self

        # Generates a valid trace identifier, a 16-byte string with at least one
        # non-zero byte.
        # AWS Docs: https://docs.aws.amazon.com/xray/latest/api/API_PutTraceSegments.html
        # hi - 4 bytes timestamp, 4 bytes random (Mid)
        # low - 8 bytes random.
        # Since we include timestamp, impossible to be invalid.
        # @return [bytes] a valid trace ID that is compliant with AWS XRay.
        def generate_trace_id
          time_hi = generate_time_bytes
          mid_and_low = RANDOM.bytes(12)
          time_hi << mid_and_low
        end

        # Generates a valid span identifier, an 8-byte string with at least one
        # non-zero byte.
        #
        # @return [bytes] a valid span ID.
        def generate_span_id
          OpenTelemetry::Trace.generate_span_id
        end

        private

        # Random number generator for generating IDs. This is an object that can
        # respond to `#bytes` and uses the system PRNG. The current logic is
        # compatible with Ruby 2.5 (which does not implement the `Random.bytes`
        # class method) and with Ruby 3.0+ (which deprecates `Random::DEFAULT`).
        # When we drop support for Ruby 2.5, this can simply be replaced with
        # the class `Random`.
        #
        # @return [#bytes]
        RANDOM = Random.respond_to?(:bytes) ? Random : Random::DEFAULT

        # Seconds since epoch converted to 4 bytes in big-endian order.
        def generate_time_bytes
          [Time.now.to_i].pack('N')
        end
      end
    end
  end
end

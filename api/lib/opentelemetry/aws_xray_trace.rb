# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # This module is entended to only be used as an override for how to generate IDs to be compliant with XRay
  module AWSXRayTrace
    extend self

    # Generates a valid trace identifier, a 16-byte string with at least one
    # non-zero byte.
    # AWS Docs: https://docs.aws.amazon.com/xray/latest/api/API_PutTraceSegments.html
    # hi - 4 bytes timestamp, 4 bytes random (Mid)
    # low - 8 bytes random.
    # Since we include timestamp, impossible to be invalid.
    # @return [bytes] a valid trace ID that is compliant with AWS XRay.
    def generate_trace_id
      time_hi = generate_time_byte
      mid = generate_variable_byte_id(4)
      low = generate_variable_byte_id(8)
      time_hi << mid << low
    end

    # Generates a valid span identifier, an 8-byte string with at least one
    # non-zero byte.
    #
    # @return [bytes] a valid span ID.
    def generate_span_id
      return generate_variable_byte_id(8)
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

    def generate_time_byte
      #get the seconds from epoch, convert to hex, then convert to bytes
      [Time.now.to_i.to_s(16)].pack('H*')
    end

    def generate_variable_byte_id(bytes = 8)
      return nil unless bytes.is_a? Numeric
      return nil unless bytes.between?(1, 256)
      invalid_id = ("\0" * bytes).b
      loop do
        id = RANDOM.bytes(bytes)
        return id unless id == invalid_id
      end
    end
  end
end

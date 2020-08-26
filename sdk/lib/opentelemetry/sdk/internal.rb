# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # @api private
    #
    # Internal contains helpers used by the reference implementation.
    module Internal
      extend self

      def boolean?(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end

      def valid_key?(key)
        key.instance_of?(String)
      end

      def valid_simple_value?(value)
        value.instance_of?(String) || value == false || value == true || value.is_a?(Numeric)
      end

      def valid_array_value?(value)
        return false unless value.is_a?(Array)
        return true if value.empty?

        case value.first
        when String
          value.all? { |v| v.instance_of?(String) }
        when TrueClass, FalseClass
          value.all? { |v| boolean?(v) }
        when Numeric
          value.all? { |v| v.is_a?(Numeric) }
        else
          false
        end
      end

      def valid_value?(value)
        valid_simple_value?(value) || valid_array_value?(value)
      end

      def valid_attributes?(attrs)
        attrs.nil? || attrs.all? { |k, v| valid_key?(k) && valid_value?(v) }
      end

      # @api private
      #
      # Returns nil if timeout is nil, 0 if timeout has expired, or the remaining (positive) time left in seconds.
      def maybe_timeout(timeout, start_time)
        return nil if timeout.nil?

        timeout -= (Time.now - start_time)
        timeout.positive? ? timeout : 0
      end
    end
  end
end

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

      def valid_value?(value)
        value.instance_of?(String) || value == false || value == true || value.is_a?(Numeric)
      end

      def valid_attributes?(attrs)
        attrs.nil? || attrs.all? { |k, v| valid_key?(k) && valid_value?(v) }
      end
    end
  end
end

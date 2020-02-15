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

      def homogenous_element_types?(value)
        first_element_type = nil
        value.each do |element|
          element_type = case element
                         when String then String
                         when TrueClass, FalseClass then :boolean
                         when Numeric then Numeric
                         end
          if !first_element_type
            first_element_type = element_type
          elsif element_type != first_element_type
            return false
          end
        end
        true
      end

      def valid_key?(key)
        key.instance_of?(String)
      end

      def valid_primitive_value?(value)
        value.instance_of?(String) || value == false || value == true || value.is_a?(Numeric)
      end

      def valid_array_value?(value)
        value.is_a?(Array) && value.all? { |elt| valid_primitive_value?(elt) } && homogenous_element_types?(value)
      end

      def valid_value?(value)
        valid_primitive_value?(value) || valid_array_value?(value)
      end

      def valid_attributes?(attrs)
        attrs.nil? || attrs.all? { |k, v| valid_key?(k) && valid_value?(v) }
      end
    end
  end
end

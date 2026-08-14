# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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
        value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
      end

      def valid_key?(key)
        key.instance_of?(String)
      end

      def numeric?(value)
        value.instance_of?(Integer) || value.instance_of?(Float)
      end

      def valid_simple_value?(value)
        value.instance_of?(String) || boolean?(value) || numeric?(value)
      end

      def valid_array_value?(value)
        return false unless value.is_a?(Array)
        return true if value.empty?

        case value.first
        when String
          value.all?(String)
        when TrueClass, FalseClass
          value.all? { |v| boolean?(v) }
        when Numeric
          value.all? { |v| numeric?(v) }
        else
          false
        end
      end

      def valid_value?(value)
        valid_simple_value?(value) || valid_array_value?(value)
      end

      # Returns an attribute value with non-UTF-8 strings normalized when they
      # can be converted without replacement. UTF-8-tagged strings are unchanged.
      #
      # @param [String, Boolean, Numeric, Array<String, Numeric, Boolean>] value
      # @return [String, Boolean, Numeric, Array<String, Numeric, Boolean>, nil]
      def normalize_attribute_value(value)
        case value
        when String
          OpenTelemetry::Common::Utilities.utf8_encode(value, placeholder: nil)
        when Array
          normalized = value.map { |element| normalize_attribute_value(element) }
          normalized unless normalized.any?(&:nil?)
        else
          value
        end
      end

      # Normalizes string encodings without validating attribute value types.
      #
      # @param [Object] owner The telemetry object that owns the attributes
      # @param [String] kind The telemetry object's kind for diagnostic messages
      # @param [Hash, nil] attrs The attributes to normalize
      # @return [Hash, nil]
      def normalize_attribute_encodings(owner, kind, attrs)
        return if attrs.nil?

        attrs.each_with_object({}) do |(key, value), normalized|
          normalized_key = normalize_attribute_value(key)
          normalized_value = normalize_attribute_value(value)
          if normalized_key.nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute key on #{kind} '#{owner}'. Dropping attribute.")
          elsif normalized_value.nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute '#{key}' on #{kind} '#{owner}'. Dropping attribute.")
          else
            normalized[normalized_key] = normalized_value
          end
        end
      end

      # Validates attributes and normalizes their string encodings.
      #
      # @param [Object] owner The telemetry object that owns the attributes
      # @param [String] kind The telemetry object's kind for diagnostic messages
      # @param [Hash, nil] attrs The attributes to validate and normalize
      # @return [Hash, nil]
      def normalize_attributes(owner, kind, attrs)
        return if attrs.nil?

        attrs.each_with_object({}) do |(key, value), normalized|
          if !valid_key?(key)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute key type #{key.class} on #{kind} '#{owner}'")
          elsif (normalized_key = normalize_attribute_value(key)).nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute key on #{kind} '#{owner}'. Dropping attribute.")
          elsif !valid_value?(value)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute value type #{value.class} for key '#{key}' on #{kind} '#{owner}'")
          elsif (normalized_value = normalize_attribute_value(value)).nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute '#{key}' on #{kind} '#{owner}'. Dropping attribute.")
          else
            normalized[normalized_key] = normalized_value
          end
        end
      end

      def valid_attributes?(owner, kind, attrs)
        attrs.nil? || attrs.each do |k, v|
          if !valid_key?(k)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute key type #{k.class} on span '#{owner}'")
            return false
          elsif normalize_attribute_value(k).nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute key on span '#{owner}'. Dropping attribute.")
            return false
          elsif !valid_value?(v)
            OpenTelemetry.handle_error(message: "invalid #{kind} attribute value type #{v.class} for key '#{k}' on span '#{owner}'")
            return false
          elsif normalize_attribute_value(v).nil?
            OpenTelemetry.handle_error(message: "invalid UTF-8 encoding for #{kind} attribute '#{k}' on span '#{owner}'. Dropping attribute.")
            return false
          end
        end

        true
      end
    end
  end
end

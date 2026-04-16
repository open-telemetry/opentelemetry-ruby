# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyTracerProvider} is an implementation of {OpenTelemetry::Trace::TracerProvider}.
    # It is the default global tracer provider returned by OpenTelemetry.tracer_provider.
    # It delegates to a "real" TracerProvider after the global tracer provider is registered.
    # It returns {ProxyTracer} instances until the delegate is installed.
    class ProxyTracerProvider < Trace::TracerProvider
      Key = Struct.new(:name, :version, :attributes)
      private_constant(:Key)

      # Returns a new {ProxyTracerProvider} instance.
      #
      # @return [ProxyTracerProvider]
      def initialize
        @mutex = Mutex.new
        @registry = {}
        @delegate = nil
      end

      # Set the delegate tracer provider. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [TracerProvider] provider The tracer provider to delegate to
      def delegate=(provider)
        unless @delegate.nil?
          OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyTracerProvider ignored.'
          return
        end

        @mutex.synchronize do
          @delegate = provider
          @delegate_supports_attributes = supports_attributes?(provider)
          @registry.each { |key, tracer| tracer.delegate = build_tracer(key.name, key.version, key.attributes) }
        end
      end

      # Returns a {Tracer} instance.
      #
      # Supports both positional arguments (legacy) and keyword arguments:
      #   tracer('name', '1.0')                                    # legacy positional
      #   tracer(name: 'name', version: '1.0', attributes: {...})  # keyword
      #
      # When both positional and keyword arguments are provided for the same
      # parameter, the keyword argument takes precedence.
      #
      # @param [String] name Instrumentation scope name
      # @param [String] version Instrumentation scope version
      # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
      #   Instrumentation scope attributes
      #
      # @return [Tracer]
      def tracer(deprecated_name = nil, deprecated_version = nil, name: nil, version: nil, attributes: nil)
        name ||= deprecated_name
        version ||= deprecated_version
        @mutex.synchronize do
          return build_tracer(name, version, attributes) unless @delegate.nil?

          @registry[Key.new(name, version, attributes)] ||= ProxyTracer.new
        end
      end

      private

      def supports_attributes?(provider)
        provider.respond_to?(:tracer) &&
          provider.method(:tracer).parameters.any? { |_, n| n == :attributes }
      end

      # Delegates to the provider's tracer method, gracefully handling
      # older SDK implementations that do not accept the attributes keyword.
      def build_tracer(name, version, attributes)
        if @delegate_supports_attributes
          @delegate.tracer(name, version, attributes: attributes)
        else
          @delegate.tracer(name, version)
        end
      end
    end
  end
end

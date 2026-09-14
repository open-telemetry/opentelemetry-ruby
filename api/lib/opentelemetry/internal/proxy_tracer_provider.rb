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
      Key = Struct.new(:name, :version, :attributes, :schema_url)
      private_constant(:Key)

      # Wraps a TracerProvider whose `#tracer` method was written before the
      # `attributes:` and `schema_url:` keyword arguments existed, dropping the
      # ones it cannot accept so that delegating to it does not raise.
      class LegacyProviderWrapper
        def initialize(legacy_provider, supports_attributes:, supports_schema_url:)
          @legacy_provider = legacy_provider
          @supports_attributes = supports_attributes
          @supports_schema_url = supports_schema_url
        end

        def tracer(name = nil, version = nil, attributes: nil, schema_url: nil)
          # Forward only the keywords this provider's tracer can accept.
          kwargs = {}
          kwargs[:attributes] = attributes if @supports_attributes
          kwargs[:schema_url] = schema_url if @supports_schema_url
          @legacy_provider.tracer(name, version, **kwargs)
        end
      end
      private_constant(:LegacyProviderWrapper)

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

        provider = wrap_if_legacy(provider)

        @mutex.synchronize do
          @delegate = provider
          @registry.each { |key, tracer| tracer.delegate = @delegate.tracer(key.name, key.version, attributes: key.attributes, schema_url: key.schema_url) }
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
      # @param [String] schema_url Instrumentation scope schema URL
      #
      # @return [Tracer]
      def tracer(deprecated_name = nil, deprecated_version = nil, name: nil, version: nil, attributes: nil, schema_url: nil)
        name ||= deprecated_name
        version ||= deprecated_version
        @mutex.synchronize do
          return @delegate.tracer(name, version, attributes: attributes, schema_url: schema_url) unless @delegate.nil?

          @registry[Key.new(name, version, attributes, schema_url)] ||= ProxyTracer.new
        end
      end

      private

      # A provider written before `attributes:` or `schema_url:` existed cannot accept
      # those keywords, so wrap it in something that drops the ones it is missing.
      def wrap_if_legacy(provider)
        supports_attributes = supports_keyword?(provider, :attributes)
        supports_schema_url = supports_keyword?(provider, :schema_url)
        return provider if supports_attributes && supports_schema_url

        LegacyProviderWrapper.new(provider, supports_attributes: supports_attributes, supports_schema_url: supports_schema_url)
      end

      def supports_keyword?(provider, keyword)
        provider.respond_to?(:tracer) &&
          provider.method(:tracer).parameters.any? { |_, name| name == keyword }
      end
    end
  end
end

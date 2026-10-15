# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

require 'opentelemetry/error'
require 'opentelemetry/context'
require 'opentelemetry/baggage'
require 'opentelemetry/trace'
require 'opentelemetry/internal'
require 'opentelemetry/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
module OpenTelemetry
  extend self

  @mutex = Mutex.new
  @tracer_provider = Internal::ProxyTracerProvider.new

  # The default for #propagation. It is not memoized in @propagation because
  # non-main Ractors can't set instance variables of modules.
  NOOP_PROPAGATOR = Context::Propagation::NoopTextMapPropagator.new.freeze
  private_constant :NOOP_PROPAGATOR

  NOOP_TRACER_PROVIDER = Trace::TracerProvider.new.freeze
  private_constant :NOOP_TRACER_PROVIDER

  DEFAULT_ERROR_HANDLER = ->(exception: nil, message: nil) { logger.error("OpenTelemetry error: #{[message, exception&.message, exception&.backtrace&.first].compact.join(' - ')}") }
  Ractor.make_shareable(DEFAULT_ERROR_HANDLER) if defined?(Ractor)
  private_constant :DEFAULT_ERROR_HANDLER

  # Registers the global logger. Non-main Ractors can only use it if it is
  # shareable between Ractors.
  #
  # @param [Logger] logger The logger to use
  def logger=(logger)
    @logger = logger
    @shareable_logger = (logger if defined?(Ractor) && Ractor.shareable?(logger))
  end

  # @return [Object, Logger] configured Logger or a default STDOUT Logger.
  #   Non-main Ractors get a default STDOUT Logger of their own unless the
  #   configured Logger is shareable.
  def logger
    return @shareable_logger || (Ractor.current[:opentelemetry_logger] ||= default_logger) if non_main_ractor?

    @logger ||= default_logger
  end

  # Configures error handler used by {handle_error}.
  #
  # Assigned object must respond to +#call+ and accept the keyword arguments
  # +exception:+ and +message:+.
  #
  # @param [#call] error_handler The error handler to use
  #
  # @example Log OpenTelemetry errors with a custom prefix
  #   OpenTelemetry.error_handler = lambda do |exception: nil, message: nil|
  #     OpenTelemetry.logger.warn("otel: #{[message, exception&.message].compact.join(' - ')}")
  #   end
  def error_handler=(error_handler)
    @error_handler = error_handler
    @shareable_error_handler = (error_handler if defined?(Ractor) && Ractor.shareable?(error_handler))
  end

  # @return [Callable] configured error handler or a default that logs the
  #   exception and message at ERROR level. Non-main Ractors get the default
  #   unless the configured error handler is shareable.
  def error_handler
    return @shareable_error_handler || DEFAULT_ERROR_HANDLER if non_main_ractor?

    @error_handler || DEFAULT_ERROR_HANDLER
  end

  # Handles an error by calling the configured error_handler.
  #
  # @param [optional Exception] exception The exception to be handled
  # @param [optional String] message An error message.
  def handle_error(exception: nil, message: nil)
    error_handler.call(exception: exception, message: message)
  end

  # Register the global tracer provider.
  #
  # @param [TracerProvider] provider A tracer provider to register as the
  #   global instance.
  def tracer_provider=(provider)
    @mutex.synchronize do
      if @tracer_provider.instance_of? Internal::ProxyTracerProvider
        logger.debug("Upgrading default proxy tracer provider to #{provider.class}")
        @tracer_provider.delegate = provider
      end
      @tracer_provider = provider
    end
  end

  # @return [Object, Trace::TracerProvider] registered tracer provider or a
  #   default no-op implementation of the tracer provider. Non-main Ractors
  #   always get a no-op tracer provider.
  def tracer_provider
    # Non-main Ractors can neither lock @mutex nor read the registered provider,
    # which isn't shareable, so they get a no-op provider.
    return NOOP_TRACER_PROVIDER if non_main_ractor?

    @mutex.synchronize { @tracer_provider }
  end

  # Registers the global propagator. Non-main Ractors can only use it if it is
  # shareable between Ractors.
  #
  # @param [Context::Propagation::Propagator] propagation The propagator to use
  def propagation=(propagation)
    @propagation = propagation
    @shareable_propagation = (propagation if defined?(Ractor) && Ractor.shareable?(propagation))
  end

  # @return [Context::Propagation::Propagator] a propagator instance. Non-main
  #   Ractors get a no-op propagator unless the registered one is shareable.
  def propagation
    return @shareable_propagation || NOOP_PROPAGATOR if non_main_ractor?

    @propagation || NOOP_PROPAGATOR
  end

  private

  def default_logger
    Logger.new($stdout, level: ENV['OTEL_LOG_LEVEL'] || Logger::INFO)
  end

  def non_main_ractor?
    defined?(Ractor) && Ractor.current != Ractor.main
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {MeterProvider} is the SDK implementation of {OpenTelemetry::Metrics::MeterProvider}.
      class MeterProvider < OpenTelemetry::Metrics::MeterProvider
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        attr_reader :resource, :metric_readers

        def initialize(resource: OpenTelemetry::SDK::Resources::Resource.create)
          @mutex = Mutex.new
          @meter_registry = {}
          @stopped = false
          @metric_readers = []
          @resource = resource
        end

        # Returns a {Meter} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Meter]
        def meter(name, version = nil)
          version ||= ''
          if @stopped
            OpenTelemetry.logger.warn 'calling MeterProvider#meter after shutdown, a noop meter will be returned.'
            OpenTelemetry::Metrics::Meter.new
          else
            @mutex.synchronize { @meter_registry[Key.new(name, version)] ||= Meter.new(name, version, self) }
          end
        end

        # Attempts to stop all the activity for this {MeterProvider}.
        #
        # Calls MetricReader#shutdown for all registered MetricReaders.
        #
        # After this is called all the newly created {Meter}s will be no-op.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling MetricProvider#shutdown multiple times.')
              Export::FAILURE
            else
              start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
              results = @metric_readers.map do |metric_reader|
                remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
                if remaining_timeout&.zero?
                  Export::TIMEOUT
                else
                  metric_reader.shutdown(timeout: remaining_timeout)
                end
              end

              @stopped = true
              results.max || Export::SUCCESS
            end
          end
        end

        # This method provides a way for provider to notify the registered
        # {MetricReader} instances, so they can do as much as they could to consume
        # or send the metrics. Note: unlike Push Metric Exporter which can send data on
        # its own schedule, Pull Metric Exporter can only send the data when it is
        # being asked by the scraper, so ForceFlush would not make much sense.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            if @stopped
              Export::SUCCESS
            else
              start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
              results = @metric_readers.map do |metric_reader|
                remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
                if remaining_timeout&.zero?
                  Export::TIMEOUT
                else
                  metric_reader.force_flush(timeout: remaining_timeout)
                end
              end

              results.max || Export::SUCCESS
            end
          end
        end

        # Adds a new MetricReader to this {MeterProvider}.
        #
        # @param metric_reader the new MetricReader to be added.
        def add_metric_reader(metric_reader)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling MetricProvider#add_metric_reader after shutdown.')
            else
              @metric_readers.push(metric_reader)
              @meter_registry.each_value { |meter| meter.add_metric_reader(metric_reader) }
            end

            nil
          end
        end

        # @api private
        def register_synchronous_instrument(instrument)
          @mutex.synchronize do
            @metric_readers.each do |mr|
              instrument.register_with_new_metric_store(mr.metric_store)
            end
          end
        end

        # The type of the Instrument(s) (optional).
        # The name of the Instrument(s). OpenTelemetry SDK authors MAY choose to support wildcard characters, with the question mark (?) matching exactly one character and the asterisk character (*) matching zero or more characters.
        # The name of the Meter (optional).
        # The version of the Meter (optional).
        # The schema_url of the Meter (optional).
        def add_view
          # TODO: For each meter add this view to all applicable instruments
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # MetricReader provides a minimal example implementation.
        # It is not required to subclass this class to provide an implementation
        # of MetricReader, provided the interface is satisfied.
        class MetricReader
          attr_reader :metric_store, :metric_producers, :resource

          # Raised when a reader is registered with a second MeterProvider.
          SINGLE_PROVIDER_ERROR = 'MetricReader cannot be registered with more than one MeterProvider'

          private_constant :SINGLE_PROVIDER_ERROR

          # @param [optional Integer] aggregation_cardinality_limit The cardinality
          #   limit applied to the SDK's own metric store.
          # @param [optional Array<MetricProducer>] metric_producers Additional
          #   MetricProducers (e.g. bridges to third-party metric sources) whose
          #   output is merged with the SDK's metric data on every #collect.
          # @param [optional MetricFilter] metric_filter The filter handed to every
          #   configured MetricProducer on #collect.
          # @param [optional Numeric] timeout The default timeout in seconds shared
          #   by the configured MetricProducers on a #collect that is not given one.
          def initialize(aggregation_cardinality_limit: nil, metric_producers: [], metric_filter: nil, timeout: nil)
            @mutex = Mutex.new
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new(cardinality_limit: aggregation_cardinality_limit)
            @metric_producers = metric_producers
            @metric_filter = metric_filter
            @timeout = timeout
            @resource = OpenTelemetry::SDK::Resources::Resource.create
          end

          # Registers this reader with a MeterProvider.
          def register_meter_provider(meter_provider)
            @mutex.synchronize do
              raise ArgumentError, SINGLE_PROVIDER_ERROR if @meter_provider && !@meter_provider.equal?(meter_provider)

              @meter_provider = meter_provider
            end
          end

          # Collects and returns the current metrics from the metric store,
          # merged with metrics from any additional configured MetricProducers.
          # metric_filter is optional to filter SDK batch and third-party batch metrics.
          # Currently the metric_filter is not applied to filter the sdk collected metrics.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds shared
          #   by all configured MetricProducers. Each producer is handed the time
          #   remaining, and producers left once it runs out are skipped. Defaults
          #   to the timeout the reader was created with.
          def collect(timeout: nil)
            timeout ||= @timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            metrics = @metric_store.collect
            metrics.concat(produce_metrics(timeout, start_time))
          end

          # No-op: subclasses should override to release resources.
          def shutdown(timeout: nil)
            Export::SUCCESS
          end

          # No-op: subclasses should override to force an export.
          def force_flush(timeout: nil)
            Export::SUCCESS
          end

          # Associates this reader and its MetricProducers with an SDK resource.
          # @api private
          def register_resource(resource)
            @resource = resource
          end

          private

          # Partial metrics from a failed result are kept; only the failure is reported.
          def produce_metrics(timeout, start_time)
            @metric_producers.flat_map do |producer|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              if remaining_timeout&.zero?
                OpenTelemetry.handle_error(message: "#{producer.class} skipped: collect timed out before producing metrics.")
                next []
              end

              result = producer.produce(resource: @resource, metric_filter: @metric_filter, timeout: remaining_timeout)
              report_producer_failure(producer, result) unless result.status == Export::SUCCESS
              with_reader_resource(result.metrics)
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: "Failed to produce metrics from #{producer.class}")
              []
            end
          end

          # The reader's resource replaces whatever resource a producer stamped on
          # its metrics, so a single collection always reports one resource.
          def with_reader_resource(metrics)
            metrics.map do |metric|
              next metric if metric.resource.equal?(@resource)

              metric.dup.tap { |copy| copy.resource = @resource }
            end
          end

          # Reports a failed producer result through the SDK error handler.
          def report_producer_failure(producer, result)
            message = "#{producer.class} failed to produce metrics with status #{result.status}."
            if result.errors.empty?
              OpenTelemetry.handle_error(message: message)
            else
              result.errors.each { |error| OpenTelemetry.handle_error(exception: error, message: message) }
            end
          end
        end
      end
    end
  end
end

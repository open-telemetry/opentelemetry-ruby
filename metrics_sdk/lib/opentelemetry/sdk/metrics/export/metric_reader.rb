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

          # @param [optional Integer] aggregation_cardinality_limit The cardinality
          #   limit applied to the SDK's own metric store.
          # @param [optional Array<MetricProducer>] metric_producers Additional
          #   MetricProducers (e.g. bridges to third-party metric sources) whose
          #   output is merged with the SDK's metric data on every #collect.
          def initialize(aggregation_cardinality_limit: nil, metric_producers: [])
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new(cardinality_limit: aggregation_cardinality_limit)
            @metric_producers = metric_producers
            @resource = OpenTelemetry::SDK::Resources::Resource.create
          end

          # Collects and returns the current metrics from the SDK's metric store,
          # merged with metrics from any additional configured MetricProducers.
          # metric_filter is optional to filter SDK batch and third-party batch metrics.
          def collect(metric_filter: nil, timeout: nil)
            metrics = @metric_store.collect
            metrics = metric_filter.filter(metrics) if metric_filter
            metrics.concat(produce_metrics(metric_filter:))
          end

          # Associates this reader and its MetricProducers with an SDK resource.
          # @api private
          def register_resource(resource)
            @resource = resource
          end

          # No-op: subclasses should override to release resources.
          def shutdown(timeout: nil)
            Export::SUCCESS
          end

          # No-op: subclasses should override to force an export.
          def force_flush(timeout: nil)
            Export::SUCCESS
          end

          private

          # Partial metrics from a failed result are kept; only the failure is reported.
          def produce_metrics(metric_filter:)
            @metric_producers.flat_map do |producer|
              result = producer.produce(resource: @resource, metric_filter:)
              report_producer_failure(producer, result) unless result.status == Export::SUCCESS
              result.metrics
            end
          end

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

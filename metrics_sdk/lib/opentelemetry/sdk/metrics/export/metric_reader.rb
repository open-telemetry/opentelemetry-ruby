# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # MetricReader
        class MetricReader
          attr_reader :exporters

          def initialize(exporter: nil)
            register_exporter(exporter)
            @mutex = Mutex.new
            @exporters = []
          end

          # The metrics Reader implementation supports registering metric Exporters
          def register_exporter(exporter: nil)
            return unless exporter.respond_to?(:pull)

            @mutex.synchronize do
              @exporters << exporter
            end
          end

          # Each exporter pull will trigger its metric_store call collect;
          # and metric_store will collect all metrics data and send for export.
          def collect
            @exporters.each { |exporter| exporter.pull if exporter.respond_to?(:pull) }
          end
          alias pull collect

          # The metrics Reader implementation supports configuring the
          # default aggregation on the basis of instrument kind.
          def aggregator(aggregator: nil, instrument_kind: nil)
            return if aggregator.nil?

            @exporters.each do |exporter|
              exporter.metric_store.metric_streams.each do |ms|
                ms.default_aggregation = aggregator if instrument_kind.nil? || ms.instrument_kind == instrument_kind
              end
            end
          end

          # The metrics Reader implementation supports configuring the
          # default temporality on the basis of instrument kind.
          def temporality(temporality: nil, instrument_kind: nil)
            return if temporality.nil?

            @exporters.each do |exporter|
              exporter.metric_store.metric_streams.each do |ms|
                ms.default_aggregation.aggregation_temporality = temporality if instrument_kind.nil? || ms.instrument_kind == instrument_kind
              end
            end
          end

          # shutdown all exporters
          def shutdown(timeout: nil)
            @exporters.each { |exporter| exporter.shutdown(timeout: timeout) if exporter.respond_to?(:shutdown) }
            Export::SUCCESS
          rescue StandardError
            Export::FAILURE
          end

          # force flush all exporters
          def force_flush(timeout: nil)
            @exporters.each { |exporter| exporter.force_flush(timeout: timeout) if exporter.respond_to?(:force_flush) }
            Export::SUCCESS
          rescue StandardError
            Export::FAILURE
          end
        end
      end
    end
  end
end

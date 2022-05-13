# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module State
        class MetricStream
          attr_reader :instrument, :resource

          def initialize(instrument, resource)
            @instrument = instrument
            @resource = resource
            @data_points = {}
            @mutex = Mutex.new
          end

          def update(measurement)
            @mutex.synchronize do
              @data_points[measurement.attributes] = if @data_points[measurement.attributes]
                                                       data_point + measurement.value
                                                     else
                                                       measurement.value
                                                     end
            end
          end

          def to_s
            metric_stream_string = String.new
            metric_stream_string << "name=#{instrument.name}"
            metric_stream_string << " description=#{instrument.description}" if instrument.description
            metric_stream_string << " unit=#{instrument.unit}" if instrument.unit
            map = @data_points.map do |attributes, value|
              str = String.new
              str << metric_stream_string
              str << " attributes=#{attributes}" if attributes
              str << " #{value}"
            end
            map.join("\n")
          end
        end
      end
    end
  end
end

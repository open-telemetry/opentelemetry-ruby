# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveModelSerializers
      # Event handler singleton for ActiveModelSerializers
      module EventHandler
        extend self

        def handle(start_timestamp, end_timestamp, payload)
          tracer.start_span(span_name(payload),
                            start_timestamp: start_timestamp,
                            attributes: build_attributes(payload),
                            kind: :internal)
                .finish(end_timestamp: end_timestamp)
        end

        protected

        def span_name(payload)
          "#{demodulize(payload[:serializer].name)} render"
        end

        def build_attributes(payload)
          {
            'serializer.name' => payload[:serializer].name,
            'serializer.renderer' => 'active_model_serializers',
            'serializer.format' => payload[:adapter]&.class&.name || 'default'
          }
        end

        def tracer
          ActiveModelSerializers::Instrumentation.instance.tracer
        end

        def demodulize(string)
          string = string.to_s
          i = string.rindex('::')
          i ? string[(i + 2)..-1] : string
        end
      end
    end
  end
end

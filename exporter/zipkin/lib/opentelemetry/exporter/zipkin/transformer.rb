# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'ipaddr'

module OpenTelemetry
  module Exporter
    module Zipkin
      # @api private
      module Transformer
        extend self

        # based on https://github.com/openzipkin/zipkin-ruby/blob/master/lib/zipkin-tracer/trace.rb
        # https://github.com/openzipkin/zipkin-go/blob/0b3ebdbc2ddf7409f84316407fec22faf1ce8a0f/model/kind.go#L21-L26https://github.com/openzipkin/zipkin-go/blob/0b3ebdbc2ddf7409f84316407fec22faf1ce8a0f/model/kind.go#L21-L26
        # https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L269-L280# based on https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L269-L280
        KIND_MAP = {
          OpenTelemetry::Trace::SpanKind::SERVER => 'SERVER',
          OpenTelemetry::Trace::SpanKind::CLIENT => 'CLIENT',
          OpenTelemetry::Trace::SpanKind::PRODUCER => 'PRODUCER',
          OpenTelemetry::Trace::SpanKind::CONSUMER => 'CONSUMER',
          OpenTelemetry::Trace::SpanKind::INTERNAL => nil
        }.freeze

        SERVICE_NAME_ATTRIBUTE_KEY = 'service.name'
        ERROR_TAG_KEY = 'error'
        STATUS_CODE_NAME = 'otel.status_code'
        STATUS_ERROR = 'ERROR'
        STATUS_OK = 'OK'
        ATTRIBUTE_PEER_SERVICE = 'peer.service'
        ATTRIBUTE_NET_PEER_IP = 'net.peer.ip'
        ATTRIBUTE_NET_PEER_PORT = 'net.peer.port'
        ATTRIBUTE_NET_HOST_IP = 'net.host.ip'
        ATTRIBUTE_NET_HOST_PORT = 'net.host.port'

        DEFAULT_SERVICE_NAME = OpenTelemetry::SDK::Resources::Resource.default.attribute_enumerator.find { |k, _| k == SERVICE_NAME_ATTRIBUTE_KEY }&.last || 'unknown_service'
        private_constant(:KIND_MAP, :DEFAULT_SERVICE_NAME, :SERVICE_NAME_ATTRIBUTE_KEY, :ERROR_TAG_KEY, :STATUS_CODE_NAME, :STATUS_ERROR, :STATUS_OK, :ATTRIBUTE_PEER_SERVICE, :ATTRIBUTE_NET_PEER_IP, :ATTRIBUTE_NET_PEER_PORT, :ATTRIBUTE_NET_HOST_IP, :ATTRIBUTE_NET_HOST_PORT)

        def to_zipkin_span(span_d, resource)
          start_time = span_d.start_timestamp / 1_000
          duration = span_d.end_timestamp / 1_000 - start_time
          tags = {}
          service_name = DEFAULT_SERVICE_NAME
          resource.attribute_enumerator.select do |key, value|
            service_name = value if key == SERVICE_NAME_ATTRIBUTE_KEY
          end

          add_il_tags(span_d, tags)
          add_status_tags(span_d, tags)
          tags = aggregate_span_tags(span_d, tags)

          # TOOO: set debug flag? (is that represented in tracestate?)
          # https://github.com/openzipkin/b3-propagation#why-is-debug-encoded-as-x-b3-flags-1
          # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L475
          # TODO: shared key mapping

          zipkin_span = {
            name: span_d.name,
            traceId: span_d.hex_trace_id,
            id: span_d.hex_span_id,
            timestamp: start_time,
            duration: duration,
            debug: false
          }

          add_conditional_tags(zipkin_span, span_d, tags, service_name)
          add_annotations(zipkin_span, span_d)

          zipkin_span
        end

        def add_il_tags(span_data, tags)
          tags['otel.library.name'] = span_data.instrumentation_library.name
          tags['otel.library.version'] = span_data.instrumentation_library.version
        end

        def add_status_tags(span_data, tags)
          if span_data.status&.code == OpenTelemetry::Trace::Status::ERROR
            # mark errors if we can, setting error key to description but falling back to an empty string
            # https://github.com/open-telemetry/opentelemetry-specification/blob/84b18b23339dcc0b1a9d48f976a1afd287417602/specification/trace/sdk_exporters/zipkin.md#status
            # https://github.com/openzipkin/zipkin-ruby/blob/7bedb4dd162c4cbeffc7b97dd06c8dbccbfbab62/lib/zipkin-tracer/trace.rb#L259
            # https://github.com/open-telemetry/opentelemetry-collector/blob/81c7cc53b7067fbf3db4e1671b13bbe2796eb56e/translator/trace/zipkin/traces_to_zipkinv2.go#L144
            tags[ERROR_TAG_KEY] = span_data.status.description || ''
            tags[STATUS_CODE_NAME] = STATUS_ERROR
          elsif span_data.status&.code == OpenTelemetry::Trace::Status::OK
            tags[STATUS_CODE_NAME] = STATUS_OK
          end
        end

        def add_conditional_tags(zipkin_span, span_data, tags, service_name)
          zipkin_span['tags'] = tags unless tags.empty?
          zipkin_span['kind'] = KIND_MAP[span_data.kind] unless span_data.kind.nil?
          zipkin_span['parentId'] = span_data.hex_parent_span_id unless span_data.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID
          zipkin_span['localEndpoint'] = endpoint_from_tags(tags, (span_data.attributes && span_data.attributes[SERVICE_NAME_ATTRIBUTE_KEY]) || service_name)
          # remote endpoint logic https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L284
          zipkin_span['remoteEndpoint'] = endpoint_from_tags(tags, nil)
        end

        def add_annotations(zipkin_span, span_data)
          # Tried to follow the below
          # https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L172
          # https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L183-L191
          # https://github.com/open-telemetry/opentelemetry-specification/blob/cb16422a61219d4fd99b466a70e47cb8af9e26b1/specification/trace/sdk_exporters/zipkin.md#events
          return if span_data.events.nil? || span_data.events.empty?

          events = span_data.events.map do |event|
            if event.attributes.keys.length.zero?
              {
                timestamp: (event.timestamp / 1_000).to_s,
                value: event.name
              }
            else
              {
                timestamp: (event.timestamp / 1_000).to_s,
                value: { event.name => event.attributes.transform_values(&:to_s) }.to_json
              }
            end
          end

          zipkin_span[:annotations] = events.map(&:to_h) unless events.empty?
        end

        def aggregate_span_tags(span_data, tags)
          # convert attributes to strings
          # https://github.com/open-telemetry/opentelemetry-specification/blob/84b18b23339dcc0b1a9d48f976a1afd287417602/specification/trace/sdk_exporters/zipkin.md#attribute
          return tags if span_data.attributes.nil?

          tags = tags.merge(span_data.attributes)

          tags.transform_values!(&:to_s)
        end

        # mostly based on https://github.com/open-telemetry/opentelemetry-specification/blob/cb16422a61219d4fd99b466a70e47cb8af9e26b1/specification/trace/sdk_exporters/zipkin.md#otlp---zipkin
        # and https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L284
        def endpoint_from_tags(tags, service_name = nil)
          endpoint = {}

          if service_name
            endpoint['serviceName'] = service_name
            endpoint['port'] = tags[ATTRIBUTE_NET_HOST_PORT].to_s if tags[ATTRIBUTE_NET_HOST_PORT]

            if tags[ATTRIBUTE_NET_HOST_IP]
              ip_addr = IPAddr.new(tags[ATTRIBUTE_NET_HOST_IP])

              # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L292
              # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L286
              if ip_addr.ipv6?
                endpoint['ipv6'] = ip_addr.to_s
              else
                endpoint['ipv4'] = ip_addr.to_s
              end
            end
          else
            endpoint['port'] = tags[ATTRIBUTE_NET_PEER_PORT].to_s if tags[ATTRIBUTE_NET_PEER_PORT]

            if tags[ATTRIBUTE_NET_PEER_IP]
              ip_addr = IPAddr.new(tags[ATTRIBUTE_NET_PEER_IP])

              # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L292
              # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L286
              if ip_addr.ipv6?
                endpoint['ipv6'] = ip_addr.to_s
              else
                endpoint['ipv4'] = ip_addr.to_s
              end
            end
          end

          endpoint
        end
      end
    end
  end
end

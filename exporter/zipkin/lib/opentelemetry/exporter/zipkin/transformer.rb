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
        STATUS_CODE_DESCRIPTION = 'otel.status_description'
        STATUS_UNSET = 'UNSET'
        STATUS_ERROR = 'ERROR'
        STATUS_OK = 'OK'
        ATTRIBUTE_PEER_SERVICE = 'peer.service'
        ATTRIBUTE_NET_PEER_IP = 'peer.ip'
        ATTRIBUTE_NET_PEER_PORT = 'peer.port'
        ATTRIBUTE_NET_HOST_IP = 'host.ip'
        ATTRIBUTE_NET_HOST_PORT = 'host.port'

        DEFAULT_SERVICE_NAME = OpenTelemetry::SDK::Resources::Resource.default.attribute_enumerator.find { |k, _| k == SERVICE_NAME_ATTRIBUTE_KEY }&.last || 'unknown_service'
        private_constant(:KIND_MAP, :DEFAULT_SERVICE_NAME, :SERVICE_NAME_ATTRIBUTE_KEY, :ERROR_TAG_KEY, :STATUS_CODE_NAME, :STATUS_CODE_DESCRIPTION, :STATUS_UNSET, :STATUS_ERROR, :STATUS_OK)

        def to_zipkin_span(span_data, resource)
          start_time = (span_data.start_timestamp.to_f * 1_000_000).to_i
          duration = (span_data.end_timestamp.to_f * 1_000_000).to_i - start_time
          tags = {}
          service_name = DEFAULT_SERVICE_NAME
          resource&.attribute_enumerator&.select do |key, value|
            if key == SERVICE_NAME_ATTRIBUTE_KEY
              service_name = value
            else
              tags[key] = value
            end
          end

          add_il_tags(span_data, tags)
          add_status_tags(span_data, tags)
          tags = aggregate_span_tags(span_data, tags)

          # TOOO: set debug flag? (is that represented in tracestate?)
          # https://github.com/openzipkin/b3-propagation#why-is-debug-encoded-as-x-b3-flags-1
          # https://github.com/openzipkin/zipkin-api/blob/7692ca7be4dc3be9225db550d60c4d30e6e9ec59/zipkin2-api.yaml#L475
          # TODO: shared key mapping
          zipkin_span = {
            name: span_data.name,
            traceId: int64(span_data.trace_id[8, 8]).to_s,
            id: int64(span_data.span_id).to_s,
            timestamp: start_time,
            duration: duration,
            debug: false
          }

          add_conditional_tags(zipkin_span, span_data, tags, service_name)
          add_annotations(zipkin_span, span_data)

          zipkin_span
        end

        def add_il_tags(span_data, tags)
          tags['otel.library.name'] = span_data.instrumentation_library&.name if span_data.instrumentation_library&.name
          tags['otel.library.version'] = span_data.instrumentation_library&.version if span_data.instrumentation_library&.version
        end

        def add_status_tags(span_data, tags)
          # https://github.com/openzipkin/zipkin-ruby/blob/7bedb4dd162c4cbeffc7b97dd06c8dbccbfbab62/lib/zipkin-tracer/trace.rb#L259
          if span_data.status&.code && span_data.status&.code == OpenTelemetry::Trace::Status::ERROR
            # mark errors if we can
            # https://github.com/open-telemetry/opentelemetry-specification/blob/84b18b23339dcc0b1a9d48f976a1afd287417602/specification/trace/sdk_exporters/zipkin.md#status
            tags[ERROR_TAG_KEY] = 'true'
            tags[STATUS_CODE_NAME] = STATUS_ERROR
          elsif span_data.status&.code && span_data.status&.code == OpenTelemetry::Trace::Status::OK
            tags[STATUS_CODE_NAME] = STATUS_OK
          else
            tags[STATUS_CODE_NAME] = STATUS_UNSET
          end

          tags[STATUS_CODE_DESCRIPTION] = span_data.status&.description if span_data.status&.description
        end

        def add_conditional_tags(zipkin_span, span_data, tags, service_name)
          zipkin_span[:tags] = tags unless tags.empty?
          zipkin_span[:kind] = KIND_MAP[span_data[:kind]] unless span_data[:kind].nil?
          zipkin_span[:parentId] = int64(span_data.parent_span_id).to_s unless span_data.parent_span_id.nil?
          zipkin_span[:localEndpoint] = endpoint_from_tags(tags, (span_data.attributes && span_data.attributes[SERVICE_NAME_ATTRIBUTE_KEY]) || service_name)
          # remote endpoint logic https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L284
          zipkin_span[:remoteEndpoint] = endpoint_from_tags(tags, nil)
        end

        def add_annotations(zipkin_span, span_data)
          # Tried to follow the below
          # https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L172
          # https://github.com/open-telemetry/opentelemetry-collector/blob/347cfa9ab21d47240128c58c9bafcc0014bc729d/translator/trace/zipkin/traces_to_zipkinv2.go#L183-L191
          # https://github.com/open-telemetry/opentelemetry-specification/blob/cb16422a61219d4fd99b466a70e47cb8af9e26b1/specification/trace/sdk_exporters/zipkin.md#events
          return if span_data.events.nil? || span_data.events&.size.to_i.zero?

          events = span_data.events&.map do |event|
            if event.attributes.keys.length.zero?
              {
                timestamp: (event.timestamp.to_f * 1_000_000).to_s,
                value: event.name
              }
            else
              {
                timestamp: (event.timestamp.to_f * 1_000_000).to_s,
                value: { "#{event.name}": event.attributes&.transform_values { |val| val.to_s } }.to_json
              }
            end
          end

          zipkin_span[:annotations] = events.map(&:to_h) unless events.empty?
        end

        def aggregate_span_tags(span_data, tags)
          # convert attributes to strings
          # https://github.com/open-telemetry/opentelemetry-specification/blob/84b18b23339dcc0b1a9d48f976a1afd287417602/specification/trace/sdk_exporters/zipkin.md#attribute
          return tags if span_data[:attributes].nil?

          tags.merge(span_data[:attributes]) do |_key, _oldval, newval|
            newval.to_s
          end
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

        def int64(byte_string)
          int = byte_string.unpack1('Q>')
          int < (1 << 63) ? int : int - (1 << 64)
        end
      end
    end
  end
end

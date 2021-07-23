# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GraphQL
      module Tracers
        # GraphQLTracer contains the OpenTelemetry tracer implementation compatible with
        # the GraphQL tracer API
        class GraphQLTracer < ::GraphQL::Tracing::PlatformTracing
          self.platform_keys = {
            'lex' => 'graphql.lex',
            'parse' => 'graphql.parse',
            'validate' => 'graphql.validate',
            'analyze_query' => 'graphql.analyze_query',
            'analyze_multiplex' => 'graphql.analyze_multiplex',
            'execute_query' => 'graphql.execute_query',
            'execute_query_lazy' => 'graphql.execute_query_lazy',
            'execute_multiplex' => 'graphql.execute_multiplex'
          }

          def platform_trace(platform_key, key, data)
            return yield if platform_key.nil?

            tracer.in_span(platform_key, attributes: attributes_for(key, data)) do |span|
              yield.tap do |response|
                if key == 'validate' && !response[:errors]&.empty?
                  span.status = OpenTelemetry::Trace::Status.error
                  response[:errors].each do |error|
                    span.add_event(
                      'graphql error',
                      attributes: error.respond_to?(:to_h) ? { 'error' => error.to_h.to_json } : nil
                    )
                  end
                end
              end
            end
          end

          def platform_field_key(type, field)
            return unless config[:enable_platform_field]

            "#{type.graphql_name}.#{field.graphql_name}"
          end

          def platform_authorized_key(type)
            return unless config[:enable_platform_authorized]

            "#{type.graphql_name}.authorized"
          end

          def platform_resolve_type_key(type)
            return unless config[:enable_platform_resolve_type]

            "#{type.graphql_name}.resolve_type"
          end

          private

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def config
            GraphQL::Instrumentation.instance.config
          end

          def attributes_for(key, data)
            attributes = {}
            case key
            when 'execute_query'
              attributes['selected_operation_name'] = data[:query].selected_operation_name if data[:query].selected_operation_name
              attributes['selected_operation_type'] = data[:query].selected_operation.operation_type
              attributes['query_string'] = data[:query].query_string
            end
            attributes
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module GraphQL
      module Patches
        # OpenTelemery Graphql platform_tracing implementation for instrumentation
        class OpenTelemetryGraphQLTracing < ::GraphQL::Tracing::PlatformTracing
          self.platform_keys = {
            'lex' => 'lex.graphql',
            'parse' => 'parse.graphql',
            'validate' => 'validate.graphql',
            'analyze_query' => 'analyze.graphql',
            'analyze_multiplex' => 'analyze.graphql',
            'execute_multiplex' => 'execute.graphql',
            'execute_query' => 'execute.graphql',
            'execute_query_lazy' => 'execute.graphql'
          }

          def platform_trace(platform_key, key, data)
            tracer.in_span(
              platform_key,
              attributes: {},
              kind: :client
            ) do |span|
              if key == 'execute_multiplex'
                operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')
                span.set_attribute('operation', operations)
              end

              if key == 'execute_query'
                span.set_attribute(:selected_operation_name, data[:query].selected_operation_name)
                span.set_attribute(:selected_operation_type, data[:query].selected_operation.operation_type)
                span.set_attribute(:query_string, data[:query].query_string)
              end
              yield
            end
          end

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def platform_field_key(type, field)
            "#{type.graphql_name}.#{field.graphql_name}"
          end

          def platform_authorized_key(type)
            "#{type.graphql_name}.authorized"
          end

          def platform_resolve_type_key(type)
            "#{type.graphql_name}.resolve_type"
          end
        end
      end
    end
  end
end

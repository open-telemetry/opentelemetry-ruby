# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Mysql2
      module Patches
        # Module to prepend to Mysql2::Client for instrumentation
        module Client
          def query(sql, options = {})
            tracer.in_span(
              database_span_name,
              attributes: client_attributes.merge(
                'db.statement' => sql
              ),
              kind: :client
            ) do
              super(sql, options)
            end
          end

          private

          def database_span_name
            # Without obfuscation or quantization of SQL Queries, setting span name
            # To the sql query woud result in PII or Cardinality issues
            # Current Otel apprroach seems to be {database.component_name}.{database_instance_name}
            # https://github.com/open-telemetry/opentelemetry-python/blob/39fa078312e6f41c403aa8cad1868264011f7546/ext/opentelemetry-ext-dbapi/tests/test_dbapi_integration.py#L53
            # This would create span names like mysql.default, mysql.replica, postgresql.staging etc etc
            database_name ? "mysql.#{database_name}" : 'mysql'
          end

          def database_name
            # https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L78
            (query_options[:database] || query_options[:dbname] || query_options[:db])&.to_s
          end

          def client_attributes
            # The client specific attributes can be found via the query_options instance variable
            # exposed on the mysql2 Client
            # https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L25-L26
            host = (query_options[:host] || query_options[:hostname]).to_s
            port = query_options[:port].to_s

            {
              'db.type' => 'mysql',
              'db.instance' => database_name,
              'db.url' => "mysql://#{host}:#{port}",
              'net.peer.name' => host,
              'net.peer.port' => port
            }
          end

          def tracer
            Mysql2::Adapter.instance.tracer
          end
        end
      end
    end
  end
end

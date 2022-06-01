# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mysql2
      module Patches
        # Module to prepend to Mysql2::Client for instrumentation
        module Client
          QUERY_NAMES = [
            'set names',
            'select',
            'insert',
            'update',
            'delete',
            'begin',
            'commit',
            'rollback',
            'savepoint',
            'release savepoint',
            'explain',
            'drop database',
            'drop table',
            'create database',
            'create table'
          ].freeze

          QUERY_NAME_RE = Regexp.new("^(#{QUERY_NAMES.join('|')})", Regexp::IGNORECASE)

          COMPONENTS_REGEX_MAP = {
            single_quotes: /'(?:[^']|'')*?(?:\\'.*|'(?!'))/,
            double_quotes: /"(?:[^"]|"")*?(?:\\".*|"(?!"))/,
            numeric_literals: /-?\b(?:[0-9]+\.)?[0-9]+([eE][+-]?[0-9]+)?\b/,
            boolean_literals: /\b(?:true|false|null)\b/i,
            hexadecimal_literals: /0x[0-9a-fA-F]+/,
            comments: /(?:#|--).*?(?=\r|\n|$)/i,
            multi_line_comments: %r{\/\*(?:[^\/]|\/[^*])*?(?:\*\/|\/\*.*)}
          }.freeze

          MYSQL_COMPONENTS = %i[
            single_quotes
            double_quotes
            numeric_literals
            boolean_literals
            hexadecimal_literals
            comments
            multi_line_comments
          ].freeze

          def query(sql, options = {})
            attributes = client_attributes
            case config[:db_statement]
            when :include
              attributes['db.statement'] = sql
            when :obfuscate
              attributes['db.statement'] = obfuscate_sql(sql)
            end
            tracer.in_span(
              database_span_name(sql),
              attributes: attributes.merge!(OpenTelemetry::Instrumentation::Mysql2.attributes),
              kind: :client
            ) do
              super(sql, options)
            end
          end

          private

          def obfuscate_sql(sql)
            if sql.size > 2000
              'SQL query too large to remove sensitive data ...'
            else
              obfuscated = sql.gsub(generated_mysql_regex, '?')
              obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if detect_unmatched_pairs(obfuscated)
              obfuscated
            end
          end

          def generated_mysql_regex
            @generated_mysql_regex ||= Regexp.union(MYSQL_COMPONENTS.map { |component| COMPONENTS_REGEX_MAP[component] })
          end

          def detect_unmatched_pairs(obfuscated)
            # We use this to check whether the query contains any quote characters
            # after obfuscation. If so, that's a good indication that the original
            # query was malformed, and so our obfuscation can't reliably find
            # literals. In such a case, we'll replace the entire query with a
            # placeholder.
            %r{'|"|\/\*|\*\/}.match(obfuscated)
          end

          def database_span_name(sql)
            # Setting span name to the SQL query without obfuscation would
            # result in PII + cardinality issues.
            # First attempt to infer the statement type then fallback to
            # current Otel approach {database.component_name}.{database_instance_name}
            # https://github.com/open-telemetry/opentelemetry-python/blob/39fa078312e6f41c403aa8cad1868264011f7546/ext/opentelemetry-ext-dbapi/tests/test_dbapi_integration.py#L53
            # This creates span names like mysql.default, mysql.replica, postgresql.staging etc.

            statement_type = extract_statement_type(sql)

            return statement_type unless statement_type.nil?

            # fallback
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

            attributes = {
              'db.system' => 'mysql',
              'net.peer.name' => host,
              'net.peer.port' => port
            }
            attributes['db.name'] = database_name if database_name
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]
            attributes
          end

          def tracer
            Mysql2::Instrumentation.instance.tracer
          end

          def config
            Mysql2::Instrumentation.instance.config
          end

          def extract_statement_type(sql)
            QUERY_NAME_RE.match(sql) { |match| match[1].downcase } unless sql.nil?
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error extracting sql statement type: #{e.message}")
          end
        end
      end
    end
  end
end

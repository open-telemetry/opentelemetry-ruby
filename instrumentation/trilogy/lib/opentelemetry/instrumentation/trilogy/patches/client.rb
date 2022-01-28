# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Trilogy
      module Patches
        # Module to prepend to Trilogy for instrumentation
        module Client # rubocop:disable Metrics/ModuleLength
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

          FULL_SQL_REGEXP = Regexp.union(MYSQL_COMPONENTS.map { |component| COMPONENTS_REGEX_MAP[component] })

          def initialize(args)
            @_otel_net_peer_name = args[:host]
            super
          end

          def query(sql)
            tracer.in_span(
              database_span_name(sql),
              attributes: client_attributes(sql),
              kind: :client
            ) do
              super(sql)
            end
          end

          private

          def client_attributes(sql)
            attributes = {
              ::OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM => 'mysql',
              ::OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => net_peer_name
            }

            attributes[::OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] unless config[:peer_service].nil?

            case config[:db_statement]
            when :obfuscate
              attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] = obfuscate_sql(sql)
            when :include
              attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] = sql
            end

            attributes
          end

          def obfuscate_sql(sql)
            if sql.size > 2000
              'SQL query too large to remove sensitive data ...'
            else
              obfuscated = sql.gsub(FULL_SQL_REGEXP, '?')
              obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if detect_unmatched_pairs(obfuscated)
              obfuscated
            end
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
            'mysql'
          end

          def net_peer_name
            if defined?(@connected_host)
              @connected_host
            elsif @_otel_net_peer_name
              @_otel_net_peer_name
            else
              'unknown sock'
            end
          end

          def tracer
            Trilogy::Instrumentation.instance.tracer
          end

          def config
            Trilogy::Instrumentation.instance.config
          end

          def extract_statement_type(sql)
            QUERY_NAME_RE.match(sql) { |match| match[1].downcase } unless sql.nil?
          rescue StandardError => e
            OpenTelemetry.logger.error("Error extracting sql statement type: #{e.message}")
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'

module OpenTelemetry
  module Instrumentation
    module PG
      module Patches
        # Module to prepend to PG::Connection for instrumentation
        module Connection
          PG::Constants::EXEC_ISH_METHODS.each do |method|
            define_method method do |*args|
              operation = extract_operation(args[0])
              extra_attrs = { 'db.statement' => obfuscate_sql(args[0]) }

              if PG::Constants::SQL_COMMANDS.include?(operation)
                span_name = "#{operation} #{database_name}"
                extra_attrs['db.operation'] = operation
              end

              tracer.in_span(
                span_name || database_name,
                attributes: client_attributes.merge(extra_attrs),
                kind: :client
              ) do
                super(*args)
              end
            end
          end

          PG::Constants::PREPARE_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name = "PREPARE #{database_name}"

              tracer.in_span(
                span_name,
                attributes: client_attributes.merge(
                  'db.statement' => obfuscate_sql(args[1]),
                  'db.operation' => 'PREPARE',
                  'db.postgresql.prepared_statement_name' => args[0]
                ),
                kind: :client
              ) do
                super(*args)
              end
            end
          end

          PG::Constants::EXEC_PREPARED_ISH_METHODS.each do |method|
            define_method method do |*args|
              # On the off-chance someone has named their prepared
              # statement something that looks like a SQL statement...
              span_name = "EXECUTE #{database_name}"

              # Note: no SQL statement is available here - we don't memoize
              # the prepared statements in this library, so all we get is the
              # prepared statement name.
              tracer.in_span(
                span_name,
                attributes: client_attributes.merge(
                  'db.operation' => 'EXECUTE',
                  'db.postgresql.prepared_statement_name' => args[0]
                ),
                kind: :client
              ) do
                super(*args)
              end
            end
          end

          private

          def tracer
            PG::Instrumentation.instance.tracer
          end

          def config
            PG::Instrumentation.instance.config
          end

          def obfuscate_sql(sql)
            return sql unless config[:enable_sql_obfuscation]

            # Borrowed from opentelemetry-instrumentation-mysql2
            return 'SQL query too large to remove sensitive data ...' if sql.size > 2000

            # From:
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscator.rb
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb
            obfuscated = sql.gsub(generated_postgres_regex, '?')
            obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if detect_unmatched_pairs(obfuscated)

            obfuscated
          end

          def generated_postgres_regex
            @generated_postgres_regex ||= Regexp.union(PG::Constants::POSTGRES_COMPONENTS.map { |component| PG::Constants::COMPONENTS_REGEX_MAP[component] })
          end

          def detect_unmatched_pairs(obfuscated)
            # From: https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb#L44
            PG::Constants::UNMATCHED_PAIRS_REGEX.match(obfuscated)
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-pg/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
          end

          def database_name
            conninfo_hash[:dbname]&.to_s
          end

          def client_attributes
            attributes = {
              'db.system' => 'postgresql',
              'db.user' => conninfo_hash[:user]&.to_s,
              'db.name' => database_name,
              'net.peer.name' => conninfo_hash[:host]&.to_s
            }
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]

            attributes.merge(transport_attrs).reject { |_, v| v.nil? }
          end

          def transport_attrs
            if conninfo_hash[:host]&.start_with?('/')
              { 'net.transport' => 'Unix' }
            else
              {
                'net.transport' => 'IP.TCP',
                'net.peer.ip' => conninfo_hash[:hostaddr]&.to_s,
                'net.peer.port' => conninfo_hash[:port]&.to_s
              }
            end
          end
        end
      end
    end
  end
end

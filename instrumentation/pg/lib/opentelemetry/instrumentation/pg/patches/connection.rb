# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'
require_relative '../lru_cache'

module OpenTelemetry
  module Instrumentation
    module PG
      module Patches
        # Module to prepend to PG::Connection for instrumentation
        module Connection
          PG::Constants::EXEC_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name, attrs = span_attrs(:query, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                super(*args)
              end
            end
          end

          PG::Constants::PREPARE_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name, attrs = span_attrs(:prepare, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                super(*args)
              end
            end
          end

          PG::Constants::EXEC_PREPARED_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name, attrs = span_attrs(:execute, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
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

          def lru_cache
            # When SQL is being sanitized, we know that this cache will
            # never be more than 50 entries * 2000 characters (so, presumably
            # 100k bytes - or 97k). When not sanitizing SQL, then this cache
            # could grow much larger - but the small cache size should otherwise
            # help contain memory growth. The intended use here is to cache
            # prepared SQL statements, so that we can attach a reasonable
            # `db.sql.statement` value to spans when those prepared statements
            # are executed later on.
            @lru_cache ||= LruCache.new(50)
          end

          # Rubocop is complaining about 19.31/18 for Metrics/AbcSize.
          # But, getting that metric in line would force us over the
          # module size limit! We can't win here unless we want to start
          # abstracting things into a million pieces.
          def span_attrs(kind, *args) # rubocop:disable Metrics/AbcSize
            if kind == :query
              operation = extract_operation(args[0])
              sql = obfuscate_sql(args[0])
            else
              statement_name = args[0]

              if kind == :prepare
                sql = obfuscate_sql(args[1])
                lru_cache[statement_name] = sql
                operation = 'PREPARE'
              else
                sql = lru_cache[statement_name]
                operation = 'EXECUTE'
              end
            end

            attrs = { 'db.operation' => validated_operation(operation), 'db.postgresql.prepared_statement_name' => statement_name }
            attrs['db.statement'] = sql unless config[:db_statement] == :omit
            attrs.reject! { |_, v| v.nil? }

            [span_name(operation), client_attributes.merge(attrs)]
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-pg/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
          end

          def span_name(operation)
            [validated_operation(operation), database_name].compact.join(' ')
          end

          def validated_operation(operation)
            operation if PG::Constants::SQL_COMMANDS.include?(operation)
          end

          def obfuscate_sql(sql)
            return sql unless config[:db_statement] == :obfuscate

            # Borrowed from opentelemetry-instrumentation-mysql2
            return 'SQL query too large to remove sensitive data ...' if sql.size > 2000

            # From:
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscator.rb
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb
            obfuscated = sql.gsub(generated_postgres_regex, '?')
            obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if PG::Constants::UNMATCHED_PAIRS_REGEX.match(obfuscated)

            obfuscated
          end

          def generated_postgres_regex
            @generated_postgres_regex ||= Regexp.union(PG::Constants::POSTGRES_COMPONENTS.map { |component| PG::Constants::COMPONENTS_REGEX_MAP[component] })
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

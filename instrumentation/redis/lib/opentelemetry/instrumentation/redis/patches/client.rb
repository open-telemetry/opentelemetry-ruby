# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        # Module to prepend to Redis::Client for instrumentation
        module Client
          MAX_VALUE_LENGTH = 50
          MAX_STATEMENT_LENGTH = 500
          private_constant :MAX_VALUE_LENGTH, :MAX_STATEMENT_LENGTH

          def process(commands) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            host = options[:host]
            port = options[:port]

            attributes = {
              'db.system' => 'redis',
              'net.peer.name' => host,
              'net.peer.port' => port
            }

            attributes['db.redis.database_index'] = options[:db] unless options[:db].zero?
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]
            attributes.merge!(OpenTelemetry::Instrumentation::Redis.attributes)

            formatted_commands = format_commands(commands)
            attributes['db.statement'] = OpenTelemetry::Common::Utilities.truncate(parse_commands(formatted_commands), MAX_STATEMENT_LENGTH)

            tracer.in_span(span_name(formatted_commands), attributes: attributes, kind: :client) do |s|
              super(commands).tap do |reply|
                if reply.is_a?(::Redis::CommandError)
                  s.record_exception(reply)
                  s.status = Trace::Status.new(
                    Trace::Status::ERROR,
                    description: reply.message
                  )
                end
              end
            end
          end

          private

          # Ensure all values are properly encoded and truncated before
          def format_commands(value)
            return nil if value.nil?
            return value.map { |v| format_commands(v) } if value.is_a?(Array)

            value = OpenTelemetry::Common::Utilities.utf8_encode(value, binary: true)
            OpenTelemetry::Common::Utilities.truncate(value, MAX_VALUE_LENGTH)
          end

          def parse_commands(commands)
            commands.map do |command|
              command = command[0] if command.is_a?(Array) && command[0].is_a?(Array)

              # If we receive an authentication request command
              # we want to short circuit parsing the commands
              # and return the obfuscated command
              return 'AUTH ?' if command[0] == 'auth'

              cmd = command[0].upcase!
              if config[:enable_statement_obfuscation]
                cmd + ' ?' * command[1..-1].size
              else
                command.join(' ')
              end
            end.join("\n")
          end

          def span_name(commands)
            commands.map do |cmd|
              cmd = cmd[0] if cmd.is_a?(Array)
              cmd = cmd[0] if cmd.is_a?(Array)
              cmd
            end.join(' ').upcase
          end

          def tracer
            Redis::Instrumentation.instance.tracer
          end

          def config
            Redis::Instrumentation.instance.config
          end
        end
      end
    end
  end
end

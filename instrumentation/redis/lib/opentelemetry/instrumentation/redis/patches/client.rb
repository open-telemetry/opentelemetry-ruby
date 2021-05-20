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
          MAX_STATEMENT_LENGTH = 500
          private_constant :MAX_STATEMENT_LENGTH

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

            parsed_commands = parse_commands(commands)
            parsed_commands = OpenTelemetry::Common::Utilities.truncate(parsed_commands, MAX_STATEMENT_LENGTH)
            parsed_commands = OpenTelemetry::Common::Utilities.utf8_encode(parsed_commands, binary: true)
            attributes['db.statement'] = parsed_commands

            tracer.in_span(span_name(commands), attributes: attributes, kind: :client) do |s|
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

          # Examples of commands received for parsing
          # Redis#queue     [[[:set, "v1", "0"]], [[:incr, "v1"]], [[:get, "v1"]]]
          # Redis#pipeline: [[:set, "v1", "0"], [:incr, "v1"], [:get, "v1"]]
          # Redis#hmset     [[:hmset, "hash", "f1", 1234567890.0987654]]
          # Redis#set       [[:set, "K", "x"]]
          def parse_commands(commands) # rubocop:disable Metrics/AbcSize
            commands.map do |command|
              # We are checking for the use of Redis#queue command, if we detect the
              # extra level of array nesting we return the first element so it
              # can be parsed.
              command = command[0] if command.is_a?(Array) && command[0].is_a?(Array)

              # If we receive an authentication request command
              # we want to short circuit parsing the commands
              # and return the obfuscated command
              return 'AUTH ?' if command[0] == :auth

              command[0] = command[0].to_s.upcase
              if config[:enable_statement_obfuscation]
                command[0] + ' ?' * (command.size - 1)
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

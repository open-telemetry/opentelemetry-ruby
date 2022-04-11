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
          SET_VALUE_SIZE_COMMANDS = %i[set]
          RETRIEVED_VALUE_SIZE_COMMANDS = %i[get mget]
          MAX_STATEMENT_LENGTH = 500
          private_constant :MAX_STATEMENT_LENGTH

          def call_pipelined(pipeline)
            return super unless config[:trace_root_spans] || OpenTelemetry::Trace.current_span.context.valid?

            # Earlier redis versions pass a command array instead of a pipeline
            # object, so set commands to a variable
            commands = pipeline.respond_to?(:commands) ? pipeline.commands : pipeline

            attributes = span_attributes(commands)
            tracer.in_span('PIPELINED', attributes: attributes, kind: :client) do |s|
              super(pipeline).tap do |responses|
                if config[:record_value_size]
                  retrieved_value_size = retrieved_value_size(responses, commands, RETRIEVED_VALUE_SIZE_COMMANDS)
                  s['db.retrieved_value_size_bytes'] = retrieved_value_size
                end
              end
            end
          end

          def process(commands) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            return super unless config[:trace_root_spans] || OpenTelemetry::Trace.current_span.context.valid?
            attributes = span_attributes(commands)

            span_name = if commands.length == 1
                          commands[0][0].to_s.upcase
                        else
                          # this is a Pipelined command, so we already created
                          # a span in call_pipelined. No need to create another.
                          return super
                        end

            tracer.in_span(span_name, attributes: attributes, kind: :client) do |s|
              super(commands).tap do |reply|
                if reply.is_a?(::Redis::CommandError)
                  s.record_exception(reply)
                  s.status = Trace::Status.error(reply.message)
                end

                if config[:record_value_size]
                  value_size = retrieved_value_size(reply, commands, RETRIEVED_VALUE_SIZE_COMMANDS)
                  s['db.retrieved_value_size'] = value_size if value_size > 0
                end
              end
            end
          end

          private

          def span_attributes(commands)
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

            # Parse commands if we need to derive span attributes from them
            if config[:db_statement] != :omit
              parsed_commands = parse_commands(commands)
              parsed_commands = OpenTelemetry::Common::Utilities.truncate(parsed_commands, MAX_STATEMENT_LENGTH)
              parsed_commands = OpenTelemetry::Common::Utilities.utf8_encode(parsed_commands, binary: true)
              attributes['db.statement'] = parsed_commands
            end

            if config[:record_value_size] && value_size = sent_value_size(commands, SET_VALUE_SIZE_COMMANDS)
              attributes['db.set_value_size_bytes'] = value_size
            end

            attributes
          end

          def calculate_bytesize(value) # rubocop:disable Metrics/CyclomaticComplexity
            case value
            when ::Redis::CommandError
              # Don't report on these; call it zero.
              0
            when String
              value.b.bytesize
            when Array
              value.sum { |s| calculate_bytesize(s) }
            when Integer
              value.size
            when Float
              # We've chosen to care about the wire representation of the value
              # This doesn't necessarily correspond to the number of bytes
              # Redis uses to store the value.
              value.to_s.bytesize
            when nil
              0
            end
          end

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

              if config[:db_statement] == :obfuscate
                command[0].to_s.upcase + ' ?' * (command.size - 1)
              else
                command_copy = command.dup
                command_copy[0] = command_copy[0].to_s.upcase
                command_copy.join(' ')
              end
            end.join("\n")
          end

          def sent_value_size(commands, commands_to_record)
            value_size = nil
            commands.map do |command|
              command = command[0] if command.is_a?(Array) && command[0].is_a?(Array)
              return nil if command[0] == :auth
              if commands_to_record.include?(command[0])
                value_size ||= 0
                value_size += calculate_bytesize(command[-1])
              end
            end
            value_size
          end

          def retrieved_value_size(reply, commands, commands_to_record)
            value_size = 0

            if commands.length == 1
              # Not a pipelined command, just calculate bytesize on reply
              command = commands[0][0] if commands[0].is_a?(Array) && commands[0][0].is_a?(Array)
              value_size = calculate_bytesize(reply) if commands_to_record.include?(commands[0][0])
            else
              # Pipelined command, return nil. Since we use same attr for the
              # bytes we SET and the bytes we GET, we can't reasonably make
              # sense of the reply.
              commands.each_with_index do |command, i|
                value_size += retrieved_value_size(reply[i], [command], commands_to_record)
              end
            end

            value_size
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

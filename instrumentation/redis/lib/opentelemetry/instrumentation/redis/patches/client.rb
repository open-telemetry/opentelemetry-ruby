# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        # Module to prepend to Redis::Client for instrumentation
        module Client # rubocop:disable Metrics/ModuleLength
          SET_VALUE_SIZE_COMMANDS = %i[hset set].freeze
          RETRIEVED_VALUE_SIZE_COMMANDS = %i[get mget].freeze
          MAX_STATEMENT_LENGTH = 500
          private_constant :MAX_STATEMENT_LENGTH

          def call_pipelined(pipeline) # rubocop:disable Metrics/AbcSize
            return super unless config[:trace_root_spans] || OpenTelemetry::Trace.current_span.context.valid?

            # Earlier redis-rb versions pass a command array instead of a
            # pipeline object, so set commands to a variable
            commands = pipeline.respond_to?(:commands) ? pipeline.commands : pipeline

            attributes = span_attributes(commands)
            span = tracer.start_span('PIPELINED', attributes: attributes, kind: :client)
            super(pipeline).tap do |responses|
              if config[:record_value_size]
                retrieved_value_size = retrieved_value_size(
                  responses, commands,
                  RETRIEVED_VALUE_SIZE_COMMANDS
                )
                span['db.retrieved_value_size_bytes'] = retrieved_value_size
              end
            rescue Exception => e # rubocop:disable Lint/RescueException
              span.record_exception(e)
              span.status = OpenTelemetry::Trace::Status.error(e.message)
              raise e
            ensure
              span.finish
            end
          end

          def process(commands) # rubocop:disable Metrics/AbcSize
            return super unless config[:trace_root_spans] || OpenTelemetry::Trace.current_span.context.valid?

            attributes = span_attributes(commands)

            # If commands length != 1, we're processing a pipelined command. In
            # that case, we can return super, since call_pipeline is already
            # monkey-patched to start a span.
            return super unless commands.length == 1

            span_name = commands[0][0].to_s.upcase

            tracer.in_span(span_name, attributes: attributes, kind: :client) do |s|
              super(commands).tap do |reply|
                if reply.is_a?(::Redis::CommandError)
                  s.record_exception(reply)
                  s.status = Trace::Status.error(reply.message)
                end

                s['db.retrieved_value_size'] = retrieved_value_size([reply], commands, RETRIEVED_VALUE_SIZE_COMMANDS) if config[:record_value_size]
              end
            end
          end

          private

          # Returns a hash of attributes to be added to a span. The config
          # settings determine the inclusion of some attributes
          #
          # @param commands [Array<Array>] the commands being run within span
          # @return [Hash] attributes
          def span_attributes(commands) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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

            if config[:record_value_size]
              attributes['db.set_value_size_bytes'] = sent_value_size(
                commands,
                SET_VALUE_SIZE_COMMANDS
              )
            end

            attributes
          end

          # Removes the outer array from commands that were issued via
          # Redis#queue command, which have an extra level of array nesting.
          #
          # @param commands [Array] an array to potentially unnest
          # @return [Array] command as a flat array
          def extract_queued_command(command)
            return command[0] if command.is_a?(Array) && command[0].is_a?(Array)

            command
          end

          # Returns the number of bytes required to transmit the value to Redis
          # over the wire.
          #
          # @return [Integer] bytes
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

          # Returns size of values being set in commands_to_record
          #
          # Examples of commands received for parsing
          # Redis#queue     [[[:set, "v1", "0"]], [[:incr, "v1"]], [[:get, "v1"]]]
          # Redis#pipeline: [[:set, "v1", "0"], [:incr, "v1"], [:get, "v1"]]
          # Redis#hmset     [[:hmset, "hash", "f1", 1234567890.0987654]]
          # Redis#set       [[:set, "K", "x"]]
          #
          # @param commands [Array<Array>] the commands to be processed
          # @return [String] sanitized, Stringified version of commands
          def parse_commands(commands) # rubocop:disable Metrics/AbcSize
            commands.map do |command|
              command = extract_queued_command(command)

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

          # Returns size of values being set in commands_to_record
          #
          # @param commands [Array<Array>]
          # @param commands_to_record [Array<Symbol>]
          # @return [Integer] size (in bytes) of values being set in
          #   commands_to_record
          def sent_value_size(commands, commands_to_record)
            value_size = 0
            commands.map do |command|
              command = extract_queued_command(command)
              return 0 if command[0] == :auth

              # command[0] is the operation (e.g. SET)
              next unless commands_to_record.include?(command[0])

              case command[0]
              when :set
                value_size += calculate_bytesize(command[-1])
              when :hset
                # hset command arrays contain an arbitrary # of key/value pairs
                # so everything in the array to calculate_bytesize except for
                # command[0] (the command) and command[1] (the name of the hash)
                value_size += calculate_bytesize(command[2..-1])
              end
            end

            value_size
          end

          # Returns size of values being set in commands_to_record
          #
          # @param value [Array<String>]
          # @param commands [Array<Array>]
          # @param commands_to_record [Array<Symbol>]
          # @return [Integer] size (in bytes) of values being set in
          #   commands_to_record
          def retrieved_value_size(value, commands, commands_to_record)
            value_size = 0

            commands.each_with_index do |command, i|
              command = extract_queued_command(command)
              value_size += calculate_bytesize(value[i]) if commands_to_record.include?(command[0])
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

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      # Utility functions
      module Utils
        extend self

        PLACEHOLDER = '?'
        VALUE_MAX_LEN = 50
        CMD_MAX_LEN = 500

        def format_span_name(commands)
          commands.map do |command|
            format_cmd(resolve_command_args(command).first)
          end.join(' ')
        end

        def format_statement(command_args)
          command_args = resolve_command_args(command_args)
          return 'AUTH ?' if auth_command?(command_args)

          cmd = format_cmd(command_args.first)
          args = command_args[1..-1].map { |arg| format_arg(arg) }
          statement = args.unshift(cmd).join(' ')
          OpenTelemetry::Common::Utilities.truncate(statement, CMD_MAX_LEN)
        end

        def format_cmd(cmd)
          format_string do
            cmd.to_s.upcase
          end
        end

        def format_statements(commands)
          commands.map { |command| format_statement(command) }.join("\n")
        end

        def format_arg(arg)
          format_string do
            obfuscate_arg(arg.to_s)
          end
        end

        private

        def obfuscate_arg(arg)
          return PLACEHOLDER if config[:enable_arg_obfuscation]

          arg
        end

        def format_string(input = nil)
          str = block_given? ? yield(input) : input
          str = OpenTelemetry::Common::Utilities.utf8_encode(str, binary: true)
          OpenTelemetry::Common::Utilities.truncate(str, VALUE_MAX_LEN)
        rescue StandardError => e
          OpenTelemetry.logger.debug("non formattable Redis arg #{str}: #{e}")
          PLACEHOLDER
        end

        def auth_command?(command_args)
          return false unless command_args.is_a?(Array) && !command_args.empty?

          command_args.first.to_sym == :auth
        end

        # Unwraps command array when Redis is called with the following syntax:
        #   redis.call([:cmd, 'arg1', ...])
        def resolve_command_args(command_args)
          return command_args.first if command_args.is_a?(Array) && command_args.first.is_a?(Array)

          command_args
        end

        def config
          ::OpenTelemetry::Instrumentation::Redis::Instrumentation.instance.config
        end
      end
    end
  end
end

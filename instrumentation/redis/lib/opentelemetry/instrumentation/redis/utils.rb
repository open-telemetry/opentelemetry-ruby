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

        def format_statements(commands)
          commands.map { |command| format_statement(command) }.join("\n")
        end

        def format_cmd(cmd)
          str = cmd.to_s.upcase
          format_string(str)
        rescue StandardError => e
          OpenTelemetry.logger.debug("non formattable Redis cmd #{str}: #{e}")
          PLACEHOLDER
        end

        def format_arg(arg)
          str = arg.to_s
          format_string(obfuscate_arg(str))
        rescue StandardError => e
          OpenTelemetry.logger.debug("non formattable Redis arg #{str}: #{e}")
          PLACEHOLDER
        end

        private

        def obfuscate_arg(arg)
          if config[:enable_statement_obfuscation]
            PLACEHOLDER
          else
            arg
          end
        end

        def format_string(input)
          str = OpenTelemetry::Common::Utilities.utf8_encode(input, binary: true)
          OpenTelemetry::Common::Utilities.truncate(str, VALUE_MAX_LEN)
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

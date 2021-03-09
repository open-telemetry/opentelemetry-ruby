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

        def format_command(command_args)
          format_arg(resolve_command_args(command_args).first)
        end

        def format_pipeline_statement(command_args)
          command_args[0].commands.map do |args|
            format_statement(args)
          end.join("\n")
        end

        def format_statement(command_args)
          command_args = resolve_command_args(command_args)
          return 'AUTH ?' if auth_command?(command_args)

          cmd = command_args.map { |x| format_arg(x) }.join(' ')
          OpenTelemetry::Common::Utilities.truncate(cmd, CMD_MAX_LEN)
        end

        def format_arg(arg)
          str = arg.is_a?(Symbol) ? arg.to_s.upcase : arg.to_s
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
      end
    end
  end
end

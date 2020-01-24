# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Redis
      # Utility functions
      module Utils
        extend self

        STRING_PLACEHOLDER = ''.encode(::Encoding::UTF_8).freeze
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
          truncate(cmd, CMD_MAX_LEN)
        end

        def format_arg(arg)
          str = arg.is_a?(Symbol) ? arg.to_s.upcase : arg.to_s
          str = utf8_encode(str, binary: true, placeholder: PLACEHOLDER)
          truncate(str, VALUE_MAX_LEN)
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

        def truncate(string, size)
          string.size > size ? "#{string[0...size - 3]}..." : string
        end

        def utf8_encode(str, options = {})
          str = str.to_s

          if options[:binary]
            # This option is useful for "gracefully" displaying binary data that
            # often contains text such as marshalled objects
            str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          elsif str.encoding == ::Encoding::UTF_8
            str
          else
            str.encode(::Encoding::UTF_8)
          end
        rescue StandardError => e
          OpenTelemetry.logger.debug("Error encoding string in UTF-8: #{e}")

          options.fetch(:placeholder, STRING_PLACEHOLDER)
        end
      end
    end
  end
end

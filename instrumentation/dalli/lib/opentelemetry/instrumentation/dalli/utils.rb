# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # Utility functions
    module Utils
      extend self

      STRING_PLACEHOLDER = ''.encode(::Encoding::UTF_8).freeze
      CMD_MAX_LEN = 500

      OPNAME_MAPPING = {
        'get'           => 'get',
        'cas'           => 'get',
        'set'           => 'set',
        'add'           => 'add',
        'replace'       => 'replace',
        'delete'        => 'delete',
        'incr'          => 'incr',
        'decr'          => 'decr',
        'flush'         => 'flush',
        'write_noop'    => 'noop',
        'version'       => 'version',
        'send_multiget' => 'getkq',
        'append'        => 'append',
        'prepend'       => 'prepend',
        'stats'         => 'stat',
        'reset_stats'   => 'stat',
        'multi_set'     => 'setq',
        'multi_add'     => 'addq',
        'multi_replace' => 'replaceq',
        'multi_delete'  => 'deleteq',
        'touch'         => 'touch',
        # 'sasl_authentication' => 'auth_negotiation',
        # 'sasl_authentication' => 'auth_request',
      }.freeze

      def opname(operation, multi)
        lookup_name = multi ? "multi_#{operation}" : operation.to_s
        OPNAME_MAPPING[lookup_name] || operation.to_s
      end

      def format_command(operation, args)
        placeholder = "#{operation} BLOB (OMITTED)"
        command = [operation, *args].join(' ').strip
        command = utf8_encode(command, binary: true, placeholder: placeholder)
        truncate(command, CMD_MAX_LEN)
      rescue => e
        OpenTelemetry.logger.debug("Error sanitizing Dalli operation: #{e}")
        placeholder
      end

      def truncate(string, size)
        string.size > size ? "#{string[0...size - 3]}..." : string
      end

      def utf8_encode(str, binary: false, placeholder: STRING_PLACEHOLDER)
        str = str.to_s

        if binary
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

        placeholder
      end
    end
  end
end


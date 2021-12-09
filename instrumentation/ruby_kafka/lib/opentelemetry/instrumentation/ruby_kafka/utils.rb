# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      # Utilities to help with instrumenting kafka
      module Utils
        module_function

        def encode_message_key(key)
          return key if key.encoding == Encoding::UTF_8 && key.valid_encoding?

          key.encode(Encoding::UTF_8)
        rescue Encoding::UndefinedConversionError
          key.unpack1('H*')
        end
      end
    end
  end
end

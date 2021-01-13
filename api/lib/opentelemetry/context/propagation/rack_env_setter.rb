# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # RackEnvSetter provides common methods for setting keys and values to
      # a rack environment. It abstracts key transformation, turning for
      # example +traceparent+ to +HTTP_TRACEPARENT+.
      class RackEnvSetter
        def set(carrier, key, value)
          carrier[to_rack_key(key)] = value
        end

        private

        def to_rack_key(key)
          ret = 'HTTP_' + key
          ret.tr!('-', '_')
          ret.upcase!
        end
      end
    end
  end
end

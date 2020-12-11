# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # The default getter module provides a common method for reading
      # a key from a carrier that implements +[]+
      module DefaultGetter
        DEFAULT_GETTER = ->(carrier, key) { carrier[key] }
        private_constant :DEFAULT_GETTER

        # Returns a callable that can read a key from a carrier that implements
        # +[]+. Useful for extract operations.
        #
        # @return [Callable]
        def default_getter
          DEFAULT_GETTER
        end
      end
    end
  end
end

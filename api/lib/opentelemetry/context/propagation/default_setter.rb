# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # The default setter module provides a common method for writing
      # a key into a carrier that implements +[]=+
      module DefaultSetter
        DEFAULT_SETTER = ->(carrier, key, value) { carrier[key] = value }
        private_constant :DEFAULT_SETTER

        # Returns a callable that can write a key into a carrier that implements
        # +[]=+. Useful for inject operations.
        #
        # @return [Callable]
        def default_setter
          DEFAULT_SETTER
        end
      end
    end
  end
end

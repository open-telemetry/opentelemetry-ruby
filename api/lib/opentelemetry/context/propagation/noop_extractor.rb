# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A no-op extractor implementation
      class NoopExtractor
        # Extract a context from the given carrier
        #
        # @param [Object] carrier The carrier to extract the context from
        # @param [Context] context The context to be upated with the extracted
        #   context
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   and returns the value associated with the key
        # @return [Context]
        def extract(carrier, context, &getter)
          context
        end
      end
    end
  end
end

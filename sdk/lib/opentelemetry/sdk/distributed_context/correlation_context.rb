# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module DistributedContext
      # SDK implementation of CorrelationContext
      class CorrelationContext
        attr_reader :entries

        # Returns a new CorrelationContext. If a parent is provided, entries
        # will be inherited by the new context, but can be overridden or removed
        # by specifiying +entries+ or +remove_keys+.
        #
        # @param [optional CorrelationContext] parent An optional parent context
        # @param [optional Hash<String,Label>] entries A hash of
        #   String-Label pairs for this context
        # @param [optional Array<String>] remove_keys Keys to be removed
        #   from this context
        def initialize(parent: nil, entries: {}, remove_keys: nil)
          @parent = parent
          @entries = if @parent
                       entries.merge!(parent.entries) { |_, v, _| v }
                     else
                       @entries = entries
                     end
          remove_keys&.each { |key| @entries.delete(key) }
          @entries.freeze
        end

        # Returns the label associated with key
        #
        # @param key
        # @return [Label]
        def [](key)
          @entries[key]
        end
      end
    end
  end
end

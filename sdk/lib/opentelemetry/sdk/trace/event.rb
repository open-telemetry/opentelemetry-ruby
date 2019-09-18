# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # A text annotation with a set of attributes and a timestamp.
      class Event
        EMPTY_ATTRIBUTES = {}.freeze

        private_constant :EMPTY_ATTRIBUTES

        # Returns the name of this event
        #
        # @return [String]
        attr_reader :name

        # Returns the attributes for this event
        #
        # @return [Hash<String, Object>]
        attr_reader :attributes

        # Returns the timestamp for this event
        #
        # @return [Time]
        attr_reader :timestamp

        # @api private
        # Returns a new event.
        #
        # @param [String] name The name of this event
        # @param [Hash<String, Object>] attributes A hash of attributes for this
        #   event. Attributes will be frozen during Event initialization.
        # @param [Time] timestamp The timestamp for this event
        # @return [Event]
        def initialize(name:, attributes:, timestamp:)
          @name = name
          @attributes = attributes.freeze || EMPTY_ATTRIBUTES
          @timestamp = timestamp
        end
      end
    end
  end
end

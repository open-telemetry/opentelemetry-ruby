# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A text annotation with a set of attributes.
    class Event
      EMPTY_ATTRIBUTES = {}.freeze

      # Returns the name of this event
      #
      # @return [String]
      attr_reader :name

      # Returns the attributes for this event
      #
      # @return [Hash<String, Object>]
      attr_reader :attributes

      # Returns a new event.
      #
      # @param [String] name The name of this event
      # @param [optional Hash<String, Object>] attributes A hash of attributes
      #   for this event. Attributes will be frozen during Event initialization.
      # @return [Event]
      def initialize(name:, attributes: nil)
        raise ArgumentError unless name.is_a?(String)
        raise ArgumentError unless Internal.valid_attributes?(attributes)

        @name = name
        @attributes = attributes.freeze || EMPTY_ATTRIBUTES
      end
    end
  end
end

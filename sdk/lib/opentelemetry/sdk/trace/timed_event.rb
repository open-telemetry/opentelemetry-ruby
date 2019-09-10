# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      class TimedEvent
        EMPTY_ATTRIBUTES = {}.freeze
        private_constant :EMPTY_ATTRIBUTES

        attr_reader :name, :attributes, :time

        def initialize(time: nil, name:, attributes: EMPTY_ATTRIBUTES)
          @time = time || Time.now
          @name = name
          @attributes = attributes
        end
      end
    end
  end
end

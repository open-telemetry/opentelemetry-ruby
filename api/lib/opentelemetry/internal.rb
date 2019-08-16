# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # Internal contains helpers used by the no-op API implementation.
  module Internal
    extend self

    def printable_ascii?(string)
      return false unless string.is_a?(String)

      r = 32..126
      string.each_codepoint { |c| return false unless r.include?(c) }
      true
    end

    def boolean?(value)
      value.is_a?(TrueClass) || value.is_a?(FalseClass)
    end
  end
end

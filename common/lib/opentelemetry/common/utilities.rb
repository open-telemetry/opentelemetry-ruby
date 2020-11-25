# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    # Utilities contains common helpers.
    module Utilities
      extend self

      # @api private
      #
      # Returns nil if timeout is nil, 0 if timeout has expired, or the remaining (positive) time left in seconds.
      def maybe_timeout(timeout, start_time)
        return nil if timeout.nil?

        timeout -= (Time.now - start_time)
        timeout.positive? ? timeout : 0
      end
    end
  end
end

require_relative './http/client_context'

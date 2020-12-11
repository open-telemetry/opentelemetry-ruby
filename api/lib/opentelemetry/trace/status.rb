# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/util/http_to_status'

module OpenTelemetry
  module Trace
    # Status represents the status of a finished {Span}. It is composed of a
    # status code in conjunction with an optional descriptive message.
    class Status
      # Convenience utility, not in API spec:
      extend Util::HttpToStatus

      # Retrieve the status code of this Status.
      #
      # @return [Integer]
      attr_reader :code

      # Retrieve the description of this Status.
      #
      # @return [String]
      attr_reader :description

      # Initialize a Status.
      #
      # @param [Integer] code One of the status codes below
      # @param [String] description
      def initialize(code, description: '')
        @code = code
        @description = description
      end

      # Returns false if this {Status} represents an error, else returns true.
      #
      # @return [Boolean]
      def ok?
        @code != ERROR
      end

      # The following represents the set of status codes of a
      # finished {Span}

      # The operation completed successfully.
      OK = 0

      # The default status.
      UNSET = 1

      # An error.
      ERROR = 2
    end
  end
end

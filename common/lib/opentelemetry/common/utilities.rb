# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    # Utilities contains common helpers.
    module Utilities
      extend self

      STRING_PLACEHOLDER = ''.encode(::Encoding::UTF_8).freeze

      # Returns nil if timeout is nil, 0 if timeout has expired,
      # or the remaining (positive) time left in seconds.
      def maybe_timeout(timeout, start_time)
        return nil if timeout.nil?

        timeout -= (Time.now - start_time)
        timeout.positive? ? timeout : 0
      end

      # Encodes a string in utf8
      #
      # @param [String] string The string to be utf8 encoded
      # @param [optional boolean] binary This option is for displaying binary data
      # @param [optional String] placeholder The fallback string to be used if encoding fails
      #
      # @return [String]
      def utf8_encode(string, binary: false, placeholder: STRING_PLACEHOLDER)
        string = string.to_s

        if binary
          # This option is useful for "gracefully" displaying binary data that
          # often contains text such as marshalled objects
          string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        elsif string.encoding == ::Encoding::UTF_8
          string
        else
          string.encode(::Encoding::UTF_8)
        end
      rescue StandardError => e
        OpenTelemetry.logger.debug("Error encoding string in UTF-8: #{e}")

        placeholder
      end

      # Truncates a string if it exceeds the size provided.
      #
      # @param [String] string The string to be truncated
      # @param [Integer] size The max size of the string
      #
      # @return [String]
      def truncate(string, size)
        string.size > size ? "#{string[0...size - 3]}..." : string
      end

      def untraced
        OpenTelemetry::Trace.with_span(OpenTelemetry::Trace::Span.new) { yield }
      end

      # Returns a URL string with userinfo removed.
      #
      # @param [String] url The URL string to cleanse.
      #
      # @return [String] the cleansed URL.
      def cleanse_url(url)
        cleansed_url = URI.parse(url)
        cleansed_url.password = nil
        cleansed_url.user = nil
        cleansed_url.to_s
      rescue URI::Error
        url
      end
    end
  end
end

require_relative './http/client_context'

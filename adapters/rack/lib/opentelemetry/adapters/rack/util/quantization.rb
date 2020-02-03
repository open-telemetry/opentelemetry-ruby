# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'
require 'set'

module OpenTelemetry
  module Adapters
    module Rack
      module Util
        # Quantization for HTTP resources
        module Quantization
          PLACEHOLDER = '?'

          module_function

          def url(url, options = {})
            url!(url, options)
          rescue StandardError
            options[:placeholder] || PLACEHOLDER
          end

          def url!(url, options = {})
            options ||= {}

            URI.parse(url).tap do |uri|
              # Format the query string
              if uri.query
                query = query(uri.query, options[:query])
                uri.query = (!query.nil? && query.empty? ? nil : query)
              end

              # Remove any URI framents
              uri.fragment = nil unless options[:fragment] == :show
            end.to_s
          end

          def query(query, options = {})
            query!(query, options)
          rescue StandardError
            options[:placeholder] || PLACEHOLDER
          end

          def query!(query, options = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            options ||= {}
            options[:show] = options[:show] || []
            options[:exclude] = options[:exclude] || []

            # Short circuit if query string is meant to exclude everything
            # or if the query string is meant to include everything
            return '' if options[:exclude] == :all
            return query if options[:show] == :all

            collect_query(query, uniq: true) do |key, value|
              if options[:exclude].include?(key)
                [nil, nil]
              else
                value = options[:show].include?(key) ? value : nil
                [key, value]
              end
            end
          end

          # Iterate over each key value pair, yielding to the block given.
          # Accepts :uniq option, which keeps uniq copies of keys without values.
          # e.g. Reduces "foo&bar=bar&bar=bar&foo" to "foo&bar=bar&bar=bar"
          def collect_query(query, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            return query unless block_given?

            uniq = options[:uniq].nil? ? false : options[:uniq]
            keys = Set.new

            delims = query.scan(/(^|&|;)/).flatten
            query.split(/[&;]/).collect.with_index do |pairs, i|
              key, value = pairs.split('=', 2)
              key, value = yield(key, value, delims[i])
              if uniq && keys.include?(key)
                ''
              elsif key && value
                "#{delims[i]}#{key}=#{value}"
              elsif key
                "#{delims[i]}#{key}".tap { keys << key }
              else
                ''
              end
            end.join.sub(/^[&;]/, '')
          end

          private_class_method :collect_query
        end
      end
    end
  end
end

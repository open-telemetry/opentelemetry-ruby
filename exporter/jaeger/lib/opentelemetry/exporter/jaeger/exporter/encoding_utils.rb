# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Jaeger
      class Exporter
        # @api private
        module EncodingUtils
          def encoded_tags(attributes)
            attributes&.map do |key, value|
              encoded_tag(key, value)
            end || EMPTY_ARRAY
          end

          def encoded_tag(key, value)
            @type_map ||= {
              LONG => Thrift::TagType::LONG,
              DOUBLE => Thrift::TagType::DOUBLE,
              STRING => Thrift::TagType::STRING,
              BOOL => Thrift::TagType::BOOL
            }.freeze

            value_key = case value
                        when Integer then LONG
                        when Float then DOUBLE
                        when String, Array then STRING
                        when false, true then BOOL
                        end
            value = value.to_json if value.is_a?(Array)
            Thrift::Tag.new(
              KEY => key,
              TYPE => @type_map[value_key],
              value_key => value
            )
          end
        end
      end
    end
  end
end

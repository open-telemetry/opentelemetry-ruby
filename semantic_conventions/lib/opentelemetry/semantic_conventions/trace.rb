# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    # Semantic conventions for trace attributes
    module Trace
      def self.const_missing(const_name)
        attribute_name = OpenTelemetry::SemanticConventions_1_20_0::Trace.const_get(const_name)
        super(const_name) unless attribute_name

        const_set(const_name, attribute_name)
        attribute_name
      end
    end
  end
end

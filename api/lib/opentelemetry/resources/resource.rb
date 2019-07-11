# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resources
    # Resource represents a resource, which captures identifying information about the entities
    # for which telemetry (metrics or traces) is reported.
    class Resource
      attr_reader :labels

      def initialize(**kvs)
        # TODO: how defensive should we be here?
        @labels = kvs.to_h { |k, v| [k.to_s.clone.freeze, v.to_s.clone.freeze] }.freeze
      end

      # TODO: Already set labels MUST NOT be overwritten unless they are empty string.
      def merge(other)
        raise ArgumentError unless other.is_a?(Resource)

        self.class.new(labels.merge(other.labels))
      end
    end
  end
end

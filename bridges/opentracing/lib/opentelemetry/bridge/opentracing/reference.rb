# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Reference provides a means of treating
      # an OpenTelemetry::Link as an OpenTracing::Reference
      class Reference
        def self.child_of(context)
          ::OpenTracing::Reference.child_of(context)
        end

        def self.follows_from(context)
          ::OpenTracing::Reference.follows_from(context)
        end

        def initialize(link, type: nil)
          @type = type
          @link = link
          @context = link.context
        end

        # @return [String] reference type
        attr_reader :type

        # @return [SpanContext] the context of a span this reference is referencing
        attr_reader :context
      end
    end
  end
end

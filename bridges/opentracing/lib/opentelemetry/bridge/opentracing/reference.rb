# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Reference provides a means of treating
      # an OpenTelemetry::Link as an OpenTracing::Reference
      # and vice versa
      class Reference
        def self.from_link(link)
          ::OpenTracing::Reference.new(nil, link.context)
        end

        def self.to_link(ref)
          OpenTelemetry::Trace::Link.new ref.context
        end
      end
    end
  end
end

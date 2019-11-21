# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module DistributedContext
      # SDK implementation of CorrelationContextManager
      class CorrelationContextManager < OpenTelemetry::DistributedContext::CorrelationContextManager
        def create_context(parent: nil, labels: nil, remove_keys: nil)
          entries = labels.each_with_object({}) { |label, memo| memo[label.key] = label }
          CorrelationContext.new(parent: parent, entries: entries, remove_keys: remove_keys)
        end
      end
    end
  end
end

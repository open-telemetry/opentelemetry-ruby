# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Transactions::ClassMethods for instrumentation
        module TransactionsClassMethods
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          module ClassMethods
            def transaction(**options, &block)
              tracer.in_span("#{self}.transaction") do
                super
              end
            end

            private

            def tracer
              ActiveRecord::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end

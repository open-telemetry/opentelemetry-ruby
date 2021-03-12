# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Transactions for instrumentation
        module Transactions
          def save!(**)
            tracer.in_span("#{self.class}#save! (Transactions)") do |_span|
              super
            end
          end

          def save(**)
            tracer.in_span("#{self.class}#save (Transactions)") do |_span|
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

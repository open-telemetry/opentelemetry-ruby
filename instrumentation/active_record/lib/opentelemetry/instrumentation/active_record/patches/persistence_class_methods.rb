# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Persistence::ClassMethods for instrumentation
        module PersistenceClassMethods
          def create!(attributes = nil, &block)
            tracer.in_span("#{self}.create!") do
              super
            end
          end

          def create(attributes = nil, &block)
            tracer.in_span("#{self}.create") do
              super
            end
          end

          def destroy(id)
            tracer.in_span("#{self}.destroy") do
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

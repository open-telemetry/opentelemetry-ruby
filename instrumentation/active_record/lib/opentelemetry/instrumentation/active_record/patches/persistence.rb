# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Persistence for instrumentation
        module Persistence
          def save!(**options, &block)
            tracer.in_span("#{self.class}#save!") do
              super
            end
          end

          def save(**options, &block)
            tracer.in_span("#{self.class}#save") do
              super
            end
          end

          def delete
            tracer.in_span("#{self.class}#delete") do
              super
            end
          end

          def destroy!
            tracer.in_span("#{self.class}#destroy!") do
              super
            end
          end

          def destroy
            tracer.in_span("#{self.class}#destroy") do
              super
            end
          end

          def update_attribute(name, value)
            tracer.in_span("#{self.class}#update_attribute") do
              super
            end
          end

          def update!(attributes)
            tracer.in_span("#{self.class}#update!") do
              super
            end
          end

          def update(attributes)
            tracer.in_span("#{self.class}#update") do
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

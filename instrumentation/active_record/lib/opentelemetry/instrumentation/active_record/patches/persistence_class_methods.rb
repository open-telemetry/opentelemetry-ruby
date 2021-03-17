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
          def create(attributes = nil, &block)
            tracer.in_span("#{self}.create") do
              super
            end
          end

          def create!(attributes = nil, &block)
            tracer.in_span("#{self}.create!") do
              super
            end
          end

          def insert(attributes, returning: nil, unique_by: nil)
            tracer.in_span("#{self}.insert") do
              super
            end
          end

          def insert_all(attributes, returning: nil, unique_by: nil)
            tracer.in_span("#{self}.insert_all") do
              super
            end
          end

          def insert!(attributes, returning: nil)
            tracer.in_span("#{self}.insert!") do
              super
            end
          end

          def insert_all!(attributes, returning: nil)
            tracer.in_span("#{self}.insert_all!") do
              super
            end
          end

          def upsert(attributes, returning: nil, unique_by: nil)
            tracer.in_span("#{self}.upsert") do
              super
            end
          end

          def upsert_all(attributes, returning: nil, unique_by: nil)
            tracer.in_span("#{self}.upsert_all") do
              super
            end
          end

          def instantiate(attributes, column_types = {}, &block)
            tracer.in_span("#{self}.instantiate") do
              super
            end
          end

          def update(id = :all, attributes) # rubocop:disable Style/OptionalArguments
            tracer.in_span("#{self}.update") do
              super
            end
          end

          def destroy(id)
            tracer.in_span("#{self}.destroy") do
              super
            end
          end

          def delete(id_or_array)
            tracer.in_span("#{self}.delete") do
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

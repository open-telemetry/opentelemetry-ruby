# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Base for instrumentating
        # insert/upsert class methods added in Rails 6.0
        module PersistenceInsertClassMethods
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          # Contains ActiveRecord::Persistence::ClassMethods to be patched
          module ClassMethods
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

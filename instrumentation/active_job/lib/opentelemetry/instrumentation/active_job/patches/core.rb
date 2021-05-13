# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Patches
        # Module to prepend to ActiveJob::Core for context propagation.
        module Core
          def self.prepended(base)
            base.class_eval do
              # Optional free-form metadata for this job; different from job
              # arguments (used for things like instrumentation or other concerns).
              attr_accessor :metadata

              def initialize(*arguments)
                super

                @metadata ||= {}
              end

              def serialize
                super.merge({ "metadata" => serialize_arguments(metadata) })
              end

              def deserialize(job_data)
                super
                self.metadata = deserialize_arguments(job_data["metadata"])
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Patches
        # Module to prepend to ActiveJob::Core for context propagation.
        module Base
          def self.prepended(base)
            base.class_eval do
              attr_accessor :metadata
            end
          end

          def initialize(*args)
            @metadata = {}
            super
          end

          def serialize
            super.merge({ "metadata" => serialize_arguments(metadata) })
          end

          def deserialize(job_data)
            self.metadata = (deserialize_arguments(job_data["metadata"]) || []).to_h
            super
          end
        end
      end
    end
  end
end

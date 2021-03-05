# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      module Patches
        # Module to prepend to LMDB::Environment for instrumentation
        module Environment
          def transaction(*args)
            tracer.in_span('TRANSACTION', attributes: { 'db.system' => 'lmdb' }) do |_span|
              super
            end
          end

          private

          def tracer
            LMDB::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end

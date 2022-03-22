# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../attribute_propagation'

module OpenTelemetry
  module Common
    module HTTP
      # ClientContext contains common helpers for context propagation
      module ClientContext
        extend OpenTelemetry::Common::AttributePropagation
      end
    end
  end
end

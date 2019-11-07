# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    module Propagation
      # @todo add class documentation
      class HTTPExtractor
        def extract(context, carrier, &getter)
          context
        end
      end
    end
  end
end

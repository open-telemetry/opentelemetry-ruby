# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    module Propagation
      # @todo add module documentation
      class HTTPInjector
        def inject(context, carrier, &setter); end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # The Samplers module contains the sampling logic for OpenTelemetry. The
      # reference implementation provides a {ProbabilitySampler}.
      module Samplers
      end
    end
  end
end

require 'opentelemetry/sdk/trace/samplers/probability_sampler'

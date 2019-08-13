# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/samplers/always_sample_sampler'
require 'opentelemetry/trace/samplers/never_sample_sampler'
require 'opentelemetry/trace/samplers/basic_decision'
require 'opentelemetry/trace/samplers/decision'

module OpenTelemetry
  module Trace
    # The Samplers module contains the sampling logic for OpenTelemetry. The
    # minimal implementation provides a {AlwaysSampleSampler} and a
    # {NeverSampleSampler}.
    module Samplers
    end
  end
end

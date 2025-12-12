# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      # The Exemplar module contains the OpenTelemetry metrics reference
      # exemplar implementations.
      module Exemplar
      end
    end
  end
end

require 'opentelemetry/sdk/metrics/exemplar/exemplar'
require 'opentelemetry/sdk/metrics/exemplar/exemplar_bucket'
require 'opentelemetry/sdk/metrics/exemplar/exemplar_filter'
require 'opentelemetry/sdk/metrics/exemplar/exemplar_reservoir'
require 'opentelemetry/sdk/metrics/exemplar/always_off_exemplar_filter'
require 'opentelemetry/sdk/metrics/exemplar/always_on_exemplar_filter'
require 'opentelemetry/sdk/metrics/exemplar/trace_based_exemplar_filter'
require 'opentelemetry/sdk/metrics/exemplar/noop_exemplar_reservoir'
require 'opentelemetry/sdk/metrics/exemplar/simple_fixed_size_exemplar_reservoir'
require 'opentelemetry/sdk/metrics/exemplar/aligned_histogram_bucket_exemplar_reservoir'

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Sum do
  let(:sum_aggregation) do
    OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(
      boundaries: boundaries,
      record_min_max: record_min_max
    )
  end

  describe '#collect' do
  end

  describe '#update' do
  end
end

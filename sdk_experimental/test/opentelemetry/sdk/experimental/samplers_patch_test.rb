# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Experimental::SamplersPatch do
  it 'upgrades Samplers' do
    _(OpenTelemetry::SDK::Trace::Samplers).must_respond_to(:parent_consistent_probability_based)
    _(OpenTelemetry::SDK::Trace::Samplers).must_respond_to(:consistent_probability_based)
  end
end

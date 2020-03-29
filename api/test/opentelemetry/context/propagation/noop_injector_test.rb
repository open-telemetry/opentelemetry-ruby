# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::NoopInjector do
  describe '#inject' do
    it 'returns the carrier unmodified' do
      context = OpenTelemetry::Context.empty.set_value('k1', 'v1')
      injector = OpenTelemetry::Context::Propagation::NoopInjector.new
      carrier = injector.inject({}, context)
      _(carrier).must_equal({})
    end
  end
end

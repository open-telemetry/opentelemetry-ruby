# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir do
  describe 'interface contract' do
    it 'requires subclasses to implement offer and collect' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      _(-> { reservoir.offer }).must_raise(NotImplementedError)
      _(-> { reservoir.collect }).must_raise(NotImplementedError)
    end
  end
end

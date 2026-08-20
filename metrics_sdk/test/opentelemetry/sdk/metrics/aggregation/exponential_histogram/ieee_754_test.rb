# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754 do
  it 'simple test min and max' do
    IEEE754 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754

    _(IEEE754.get_ieee_754_exponent(Float::MAX)).must_equal(1023)
    _(IEEE754.get_ieee_754_exponent(Float::MIN)).must_equal(-1022)

    _(IEEE754.get_ieee_754_mantissa(Float::MAX)).must_equal(4_503_599_627_370_495)
    _(IEEE754.get_ieee_754_mantissa(Float::MIN)).must_equal(0)
  end
end

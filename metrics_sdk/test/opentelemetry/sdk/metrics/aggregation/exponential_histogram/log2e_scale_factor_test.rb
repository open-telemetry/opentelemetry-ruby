# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::Log2eScaleFactor do
  it 'ensure the log 2 scale factor is correct' do
    Log2eScaleFactor = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::Log2eScaleFactor

    _(Log2eScaleFactor.log2e_scale_buckets).must_equal([1.4426950408889634,
                                                        2.8853900817779268,
                                                        5.7707801635558535,
                                                        11.541560327111707,
                                                        23.083120654223414,
                                                        46.16624130844683,
                                                        92.33248261689366,
                                                        184.6649652337873,
                                                        369.3299304675746,
                                                        738.6598609351493,
                                                        1477.3197218702985,
                                                        2954.639443740597,
                                                        5909.278887481194,
                                                        11_818.557774962388,
                                                        23_637.115549924776,
                                                        47_274.23109984955,
                                                        94_548.4621996991,
                                                        189_096.9243993982,
                                                        378_193.8487987964,
                                                        756_387.6975975928,
                                                        1_512_775.3951951857])
  end
end

# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::BatchSampledSpanProcessor do
  BatchSampledSpanProcessor = OpenTelemetry::SDK::Trace::MultiSpanProcessor

  class TestExporter
    def export(batch)
      batches << batch
    end

    def batches
      @batches ||= []
    end
  end

  describe 'lifecycle' do
    it 'should stop and start correctly' do
      bsp = BatchSampledSpanProcessor.new(exporter: TestExporter.new)
      bsp.shutdown
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Status do
  let(:trace_status) { OpenTelemetry::Trace::Status }

  describe '.code' do
    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.ok
      _(status.code).must_equal(0)
    end
  end

  describe '.description' do
    it 'is an empty string by default' do
      status = OpenTelemetry::Trace::Status.ok
      _(status.description).must_equal('')
    end

    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.ok('ok')
      _(status.description).must_equal('ok')
    end
  end

  describe '.ok?' do
    it 'reflects code when OK' do
      status = OpenTelemetry::Trace::Status.ok
      _(status.ok?).must_equal(true)
    end

    it 'reflects code when not OK' do
      status = OpenTelemetry::Trace::Status.error
      _(status.ok?).must_equal(false)
    end
  end
end

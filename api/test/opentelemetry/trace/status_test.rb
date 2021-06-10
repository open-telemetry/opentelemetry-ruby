# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Status do
  let(:trace_status) { OpenTelemetry::Trace::Status }

  describe '.code' do
    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.new(0)
      _(status.code).must_equal(0)
    end
  end

  describe '.description' do
    it 'is an empty string by default' do
      status = OpenTelemetry::Trace::Status.new(0)
      _(status.description).must_equal('')
    end

    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.new(0, description: 'ok')
      _(status.description).must_equal('ok')
    end
  end

  describe '.initialize' do
    it 'initializes a Status with required arguments' do
      status = OpenTelemetry::Trace::Status.new(0, description: 'this is ok')
      _(status.code).must_equal(0)
      _(status.description).must_equal('this is ok')
    end
  end

  describe '.ok?' do
    it 'reflects code when OK' do
      ok = OpenTelemetry::Trace::Status::OK
      status = OpenTelemetry::Trace::Status.new(ok)
      _(status.ok?).must_equal(true)
    end

    it 'reflects code when not OK' do
      codes = OpenTelemetry::Trace::Status.constants - %i[OK UNSET]
      codes.each do |code|
        code = OpenTelemetry::Trace::Status.const_get(code)
        status = OpenTelemetry::Trace::Status.new(code)
        _(status.ok?).must_equal(false)
      end
    end
  end
end

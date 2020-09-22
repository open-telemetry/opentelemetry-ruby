# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Status do
  let(:trace_status) { OpenTelemetry::Trace::Status }

  describe '.http_to_status' do
    it 'returns Status' do
      _(trace_status.http_to_status(200)).must_be_kind_of trace_status
    end

    def assert_http_to_status(http_code, trace_status_code)
      _(trace_status.http_to_status(http_code).canonical_code).must_equal trace_status_code
    end

    it 'maps http 1xx codes' do
      assert_http_to_status(100, trace_status::OK)
      assert_http_to_status(199, trace_status::OK)
    end

    it 'maps http 2xx codes' do
      assert_http_to_status(200, trace_status::OK)
      assert_http_to_status(299, trace_status::OK)
    end

    it 'maps http 3xx codes' do
      assert_http_to_status(300, trace_status::OK)
      assert_http_to_status(399, trace_status::OK)
    end

    it 'maps http 4xx codes' do
      assert_http_to_status(400, trace_status::ERROR)
      assert_http_to_status(499, trace_status::ERROR)
    end

    it 'maps http 5xx codes' do
      assert_http_to_status(500, trace_status::ERROR)
      assert_http_to_status(599, trace_status::ERROR)
    end
  end

  describe '.canonical_code' do
    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.new(0)
      _(status.canonical_code).must_equal(0)
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
      _(status.canonical_code).must_equal(0)
      _(status.description).must_equal('this is ok')
    end
  end

  describe '.ok?' do
    it 'reflects canonical_code when OK' do
      ok = OpenTelemetry::Trace::Status::OK
      status = OpenTelemetry::Trace::Status.new(ok)
      _(status.ok?).must_equal(true)
    end

    it 'reflects canonical_code when not OK' do
      canonical_codes = OpenTelemetry::Trace::Status.constants - %i[OK UNSET]
      canonical_codes.each do |canonical_code|
        code = OpenTelemetry::Trace::Status.const_get(canonical_code)
        status = OpenTelemetry::Trace::Status.new(code)
        _(status.ok?).must_equal(false)
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/http'

describe OpenTelemetry::Instrumentation::HTTP do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::HTTP'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'present' do
    it 'when http gem installed' do
      _(instrumentation.present?).must_equal(true)
    end

    it 'when HTTP constant not present' do
      hide_const('HTTP')
      _(instrumentation.present?).must_equal(false)
    end

    it 'when http gem not installed' do
      allow(Gem).to receive(:loaded_specs).and_return({})
      _(instrumentation.present?).must_equal(false)
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/koala'

describe OpenTelemetry::Instrumentation::Koala do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Koala::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Koala'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      instrumentation.install({})
    end
  end

  describe 'present' do
    it 'when koala gem installed' do
      _(instrumentation.present?).must_equal true
    end

    # it 'when koala gem not installed' do
    # hide_const('Koala')
    # _(instrumentation.present?).must_equal false
    # end
  end
end

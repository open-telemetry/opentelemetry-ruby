# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/manticore'

describe 'OpenTelemetry::Instrumentation::Manticore' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Manticore::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal('OpenTelemetry::Instrumentation::Manticore')
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#present' do
    it 'installs instrumentation' do
      _(instrumentation.present?).must_equal(true)
    end

    describe 'when Manticore::Response const is not available' do
      before do
        hide_const('Manticore::Response')
      end

      it 'does not install instrumentation' do
        assert_nil(instrumentation.present?)
      end
    end

    describe 'when ruby platform is not java' do
      before do
        RUBY_PLATFORM = 'ruby'
      end
      after do
        RUBY_PLATFORM = 'java'
      end
      it 'does not install instrumentation' do
        _(instrumentation.present?).must_equal(false)
      end
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end
end
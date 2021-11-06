# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  let(:minimum_version) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation::MINIMUM_VERSION }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::ActiveJob'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#compatible' do
    it 'returns false for unsupported gem versions' do
      Gem.stub(:loaded_specs, 'activejob' => Gem::Specification.new { |s| s.version = '4.2.0' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'returns true for supported gem versions' do
      Gem.stub(:loaded_specs, 'activejob' => Gem::Specification.new { |s| s.version = minimum_version }) do
        _(instrumentation.compatible?).must_equal true
      end
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end
end

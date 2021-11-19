# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/ruby_kafka'

describe OpenTelemetry::Instrumentation::RubyKafka::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::RubyKafka'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'present' do
    it 'when ruby-kafka gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when ruby-kafka gem not installed' do
      hide_const('Kafka')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      Gem.stub(:loaded_specs, 'ruby-kafka' => Gem::Specification.new { |s| s.version = '0.6.8' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'when future gem version installed' do
      Gem.stub(:loaded_specs, 'ruby-kafka' => Gem::Specification.new { |s| s.version = '1.7.0' }) do
        _(instrumentation.compatible?).must_equal true
      end
    end

    describe 'when the installing application bypasses RubyGems' do
      it 'falls back to the VERSION constant' do
        stub_const('Kafka::VERSION', '0.6.9')
        Gem.stub(:loaded_specs, 'ruby-kafka' => nil) do
          _(instrumentation.compatible?).must_equal false
        end

        version = ::OpenTelemetry::Instrumentation::RubyKafka::Instrumentation::MINIMUM_VERSION.version
        stub_const('Kafka::VERSION', version)
        Gem.stub(:loaded_specs, 'ruby-kafka' => nil) do
          _(instrumentation.compatible?).must_equal true
        end
      end
    end
  end

  describe '#install' do
    it 'accepts arguments' do
      instrumentation.instance_variable_set(:@installed, false)
      _(instrumentation.install({})).must_equal(true)
    end
  end
end

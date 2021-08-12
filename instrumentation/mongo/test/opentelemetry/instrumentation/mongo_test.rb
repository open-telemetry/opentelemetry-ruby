# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require_relative '../../test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/mongo/instrumentation'

describe OpenTelemetry::Instrumentation::Mongo do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Mongo::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    # Clear previous instrumentation subscribers between test runs
    Mongo::Monitoring::Global.subscribers['Command'] = [] if defined?(::Mongo::Monitoring::Global)
    instrumentation.install
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'present' do
    it 'when mongo gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when mongo gem not installed' do
      hide_const('Mongo')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      allow_any_instance_of(Bundler::StubSpecification).to receive(:version).and_return(Gem::Version.new('2.4.3'))
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      allow_any_instance_of(Bundler::StubSpecification).to receive(:version).and_return(Gem::Version.new('3.0.0'))
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'install' do
    it 'installs the subscriber' do
      klass = OpenTelemetry::Instrumentation::Mongo::Subscriber
      subscribers = Mongo::Monitoring::Global.subscribers['Command']

      _(subscribers.size).must_equal 1
      _(subscribers.first).must_be_kind_of klass
    end
  end

  describe 'tracing' do
    before do
      TestHelper.setup_mongo
    end

    after do
      TestHelper.teardown_mongo
    end

    it 'before job' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after job' do
      client = TestHelper.client

      client['people'].insert_one(name: 'Steve', hobbies: ['hiking'])
      _(exporter.finished_spans.size).must_equal 1

      client['people'].find(name: 'Steve').first
      _(exporter.finished_spans.size).must_equal 2
    end
  end unless ENV['OMIT_SERVICES']
end

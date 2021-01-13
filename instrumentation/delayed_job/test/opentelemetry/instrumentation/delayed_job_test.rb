# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/delayed_job/instrumentation'

describe OpenTelemetry::Instrumentation::DelayedJob do
  let(:instrumentation) { OpenTelemetry::Instrumentation::DelayedJob::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    instrumentation.install
    exporter.reset
  end

  describe 'present' do
    it 'when delayed_job gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when delayed_job gem not installed' do
      hide_const('Delayed')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      Gem.stub(:loaded_specs, 'delayed_job' => Gem::Specification.new { |s| s.version = '4.0.3' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'when future gem version installed' do
      Gem.stub(:loaded_specs, 'delayed_job' => Gem::Specification.new { |s| s.version = '5.3.0' }) do
        _(instrumentation.compatible?).must_equal true
      end
    end
  end

  describe 'install' do
    it 'installs the tracer plugin' do
      klass = OpenTelemetry::Instrumentation::DelayedJob::Plugins::TracerPlugin
      _(Delayed::Worker.plugins).must_include klass
    end
  end

  describe 'tracing' do
    before do
      TestHelper.setup_active_record
    end

    after do
      TestHelper.teardown_active_record
    end

    it 'before job' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after job' do
      payload = Class.new do
        def perform
          true
        end
      end

      job = Delayed::Job.enqueue(payload.new)
      _(exporter.finished_spans.size).must_equal 1

      Delayed::Worker.new.run(job)
      _(exporter.finished_spans.size).must_equal 2
    end
  end
end

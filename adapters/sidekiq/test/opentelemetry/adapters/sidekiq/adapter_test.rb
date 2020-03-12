# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/adapters/sidekiq'

class SimpleEnqueueingJob
  include Sidekiq::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Sidekiq::Worker

  def perform
    puts 'Simple work accomplished'
  end
end

describe OpenTelemetry::Adapters::Sidekiq::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Sidekiq::Adapter.instance }
  let(:exporter) { EXPORTER }
  before { exporter.reset }

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after performing a simple job' do
      Sidekiq::Testing.inline! { SimpleJob.perform_async }

      _(exporter.finished_spans.size).must_equal 2
    end

    it 'after performing a simple job enqueuer' do
      Sidekiq::Testing.inline! { SimpleEnqueueingJob.perform_async }

      _(exporter.finished_spans.size).must_equal 4
    end
  end
end

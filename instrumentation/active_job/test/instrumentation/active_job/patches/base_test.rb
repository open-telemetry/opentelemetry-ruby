# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Patches::Base do
  describe 'attr_accessor' do
    it 'adds a "metadata" accessor' do
      job = TestJob.new

      _(job).must_respond_to :metadata
      _(job).must_respond_to :metadata=
    end
  end

  describe 'serialization / deserialization' do
    it 'must handle metadata' do
      job = TestJob.new
      job.metadata = { 'foo' => 'bar' }

      serialized_job = job.serialize
      _(serialized_job.keys).must_include 'metadata'

      job = TestJob.new
      job.deserialize(serialized_job)
      _(job.metadata).must_equal('foo' => 'bar')
    end
  end
end

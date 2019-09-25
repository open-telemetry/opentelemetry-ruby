# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingShim::TracerShim do
  let(:mock_tracer) { Minitest::Mock.new }
  let(:tracer_shim) { OpenTelemetry::OpenTracingShim::TracerShim.new mock_tracer }
  describe '#active_span' do
    it 'gets the tracers active span' do
      mock_tracer.expect(:current_span, 'an_active_span')
      as = tracer_shim.active_span
      as.must_equal 'an_active_span'
      mock_tracer.verify
    end
  end

  describe '#start_span' do
    it 'calls start span on the tracer' do
      args = ['name', { with_parent: 'parent', attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      mock_tracer.expect(:start_span, 'an_active_span', args)
      tracer_shim.start_span('name', child_of: 'parent', references: 'refs', tags: 'tag', start_time: 'now')
      mock_tracer.verify
    end
  end

  describe '#start_active_span' do
    it 'calls start span on the tracer and with_span to make active' do
      args = ['name', { with_parent: 'parent', attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      mock_tracer.expect(:start_span, 'an_active_span', args)
      mock_tracer.expect(:with_span, nil, ['an_active_span'])
      tracer_shim.start_active_span('name', child_of: 'parent', references: 'refs', tags: 'tag', start_time: 'now')
      mock_tracer.verify
    end
  end

  describe '#inject' do
    # TODO: leaving tbd as binary_format case needs to be worked out and needs to call super
  end

  describe '#extract' do
    # TODO: leaving tbd as binary_format case needs to be worked out and needs to call super
  end
end

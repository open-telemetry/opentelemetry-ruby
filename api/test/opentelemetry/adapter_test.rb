# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Adapter do
  class TestAdapter < OpenTelemetry::Adapter
    attr_accessor :state
    def install
      self.state = :called_install
      self
    end
  end

  class TestAdapter2 < OpenTelemetry::Adapter
    def install; end
  end

  describe '.install' do
    before do
      @test_adapter = TestAdapter.install(config: { name: 'foo', version: 'bar' })
      TestAdapter2.install(config: { name: 'foo2', version: 'bar2' })
    end

    it 'retains configuration separately' do
      _(TestAdapter.config[:name]).must_equal 'foo'
      _(TestAdapter2.config[:name]).must_equal 'foo2'
    end

    it 'provides default propagation_format' do
      _(TestAdapter.propagation_format).wont_be_nil
    end

    it 'provides default tracer' do
      _(TestAdapter.tracer).wont_be_nil
    end

    it 'calls #install on subclass' do
      _(@test_adapter.state).must_equal :called_install
    end
  end
end

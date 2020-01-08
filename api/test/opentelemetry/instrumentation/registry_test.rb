# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Registry do
  after do
    OpenTelemetry.instance_variable_set(:@instrumentation_registry, nil)
  end

  let(:registry) do
    OpenTelemetry::Instrumentation::Registry.new
  end

  let(:adapter) do
    Class.new(OpenTelemetry::Instrumentation::Adapter) do
      adapter_name 'TestAdapter'
      adapter_version '0.1.1'
    end
  end

  describe '#register, #lookup' do
    it 'registers and looks up adapters' do
      registry.register(adapter)
      _(registry.lookup(adapter.instance.name)).must_equal(adapter.instance)
    end
  end

  describe 'installation' do
    before do
      TestAdapter1 = Class.new(OpenTelemetry::Instrumentation::Adapter) do
        install { 1 + 1 }
      end
      TestAdapter2 = Class.new(OpenTelemetry::Instrumentation::Adapter) do
        install { 2 + 2 }
      end
      @adapters = [TestAdapter1, TestAdapter2]
      @adapters.each { |adapter| registry.register(adapter) }
    end

    after do
      @adapters.each { |adapter| Object.send(:remove_const, adapter.name.to_sym) }
    end

    describe '#install_all' do
      it 'installs all registered adapters by default' do
        _(@adapters.map(&:instance).none? { |a| a.installed? }) # rubocop:disable Style/SymbolProc
          .must_equal(true)
        registry.install_all
        _(@adapters.map(&:instance).all? { |a| a.installed? }).must_equal(true) # rubocop:disable Style/SymbolProc
      end

      it 'passes config to adapters when installing' do
        _(TestAdapter1.instance.config).must_equal({})
        _(TestAdapter2.instance.config).must_equal({})

        registry.install_all('TestAdapter1' => { a: 'a' },
                             'TestAdapter2' => { b: 'b' })

        _(TestAdapter1.instance.config).must_equal(a: 'a')
        _(TestAdapter2.instance.config).must_equal(b: 'b')
      end
    end

    describe '#install' do
      it 'installs specified adapters' do
        _(@adapters.map(&:instance).none? { |a| a.installed? }) # rubocop:disable Style/SymbolProc
          .must_equal(true)
        registry.install(%w[TestAdapter1])
        _(TestAdapter1.instance.installed?).must_equal(true)
        _(TestAdapter2.instance.installed?).must_equal(false)
      end

      it 'passes config to adapters when installing' do
        _(TestAdapter1.instance.config).must_equal({})
        _(TestAdapter2.instance.config).must_equal({})

        registry.install(%w[TestAdapter1 TestAdapter2],
                         'TestAdapter1' => { a: 'a' },
                         'TestAdapter2' => { b: 'b' })

        _(TestAdapter1.instance.config).must_equal(a: 'a')
        _(TestAdapter2.instance.config).must_equal(b: 'b')
      end
    end
  end
end

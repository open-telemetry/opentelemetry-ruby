# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::ClassScopedAttributes do
  DemoExtendingClass = Class.new { extend OpenTelemetry::Common::ClassScopedAttributes }

  describe '#attributes' do
    let(:attributes) { { 'foo' => 'bar' } }

    it 'returns an empty hash by default' do
      _(DemoExtendingClass.attributes).must_equal({})
    end

    it 'returns the current attributes hash' do
      DemoExtendingClass.with_attributes(attributes) do
        _(DemoExtendingClass.attributes).must_equal(attributes)
      end
    end

    it 'returns the current attributes hash from the provided context' do
      context = DemoExtendingClass.context_with_attributes(attributes, parent_context: OpenTelemetry::Context.empty)
      _(DemoExtendingClass.attributes).wont_equal(attributes)
      _(DemoExtendingClass.attributes(context)).must_equal(attributes)
    end
  end

  describe '#with_attributes' do
    it 'yields the passed in attributes' do
      DemoExtendingClass.with_attributes('foo' => 'bar') do |attributes|
        _(attributes).must_equal('foo' => 'bar')
      end
    end

    it 'yields context containing attributes' do
      DemoExtendingClass.with_attributes('foo' => 'bar') do |attributes, context|
        _(context).must_equal(OpenTelemetry::Context.current)
        _(DemoExtendingClass.attributes).must_equal(attributes)
      end
    end

    it 'should reactivate the attributes after the block' do
      DemoExtendingClass.with_attributes('foo' => 'bar') do
        _(DemoExtendingClass.attributes).must_equal('foo' => 'bar')

        DemoExtendingClass.with_attributes('foo' => 'baz') do
          _(DemoExtendingClass.attributes).must_equal('foo' => 'baz')
        end

        _(DemoExtendingClass.attributes).must_equal('foo' => 'bar')
      end
    end

    it 'should merge attributes' do
      DemoExtendingClass.with_attributes(
        'a' => '1',
        'c' => '2'
      ) do
        _(DemoExtendingClass.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )

        DemoExtendingClass.with_attributes(
          'a' => '0',
          'b' => '1'
        ) do
          _(DemoExtendingClass.attributes).must_equal(
            'a' => '0',
            'b' => '1',
            'c' => '2'
          )
        end

        _(DemoExtendingClass.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )
      end
    end
  
    it "namespaces attributes to extending class" do
      ExtendingClass1 = Class.new { extend OpenTelemetry::Common::ClassScopedAttributes }
      ExtendingClass2 = Class.new { extend OpenTelemetry::Common::ClassScopedAttributes } 
      extending_class_1_attrs = nil
      extending_class_2_attrs = nil
      shared_key = "don't overwrite me"
      ExtendingClass1.with_attributes(shared_key => "first value") do |attributes|
        ExtendingClass2.with_attributes(shared_key => "second value") do |attributes|
          extending_class_1_attrs = ExtendingClass1.attributes
          extending_class_2_attrs = ExtendingClass2.attributes
        end
      end
    
      _(extending_class_1_attrs).must_equal({shared_key => "first value"})
      _(extending_class_2_attrs).must_equal({shared_key => "second value"})
    end

    it "namespaces attributes to extending module" do
      ExtendingModule1 = Module.new { extend OpenTelemetry::Common::ClassScopedAttributes }
      ExtendingModule2 = Module.new { extend OpenTelemetry::Common::ClassScopedAttributes } 
      extending_module_1_attrs = nil
      extending_module_2_attrs = nil
      shared_key = "don't overwrite me"
      ExtendingModule1.with_attributes(shared_key => "first value") do |attributes|
        ExtendingModule2.with_attributes(shared_key => "second value") do |attributes|
          extending_module_1_attrs = ExtendingModule1.attributes
          extending_module_2_attrs = ExtendingModule2.attributes
        end
      end
    
      _(extending_module_1_attrs).must_equal({shared_key => "first value"})
      _(extending_module_2_attrs).must_equal({shared_key => "second value"})
    end
  end

  describe '#context_with_attributes' do
    it 'returns a context containing attributes' do
      attrs = { 'foo' => 'bar' }
      ctx = DemoExtendingClass.context_with_attributes(attrs)
      _(DemoExtendingClass.attributes(ctx)).must_equal(attrs)
    end

    it 'returns a context containing attributes' do
      parent_ctx = OpenTelemetry::Context.empty.set_value('foo', 'bar')
      ctx = DemoExtendingClass.context_with_attributes({ 'bar' => 'baz' }, parent_context: parent_ctx)
      _(DemoExtendingClass.attributes(ctx)).must_equal('bar' => 'baz')
      _(ctx.value('foo')).must_equal('bar')
    end
  end
end
# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Internal do
  let(:klass) { OpenTelemetry::SDK::Internal }

  describe '.to_boolean' do
    it 'String true case' do
      _(klass.to_boolean('true')).must_equal true
      _(klass.to_boolean('yes')).must_equal true
      _(klass.to_boolean('t')).must_equal true
      _(klass.to_boolean('y')).must_equal true
      _(klass.to_boolean('1')).must_equal true
    end

    it 'String false case' do
      _(klass.to_boolean('false')).must_equal false
      _(klass.to_boolean('no')).must_equal false
      _(klass.to_boolean('f')).must_equal false
      _(klass.to_boolean('n')).must_equal false
      _(klass.to_boolean('0')).must_equal false
    end

    it 'String nil case' do
      assert_nil(klass.to_boolean('foo'))
    end

    it 'Symbol true case' do
      _(klass.to_boolean(:true)).must_equal true # rubocop:disable Lint/BooleanSymbol
      _(klass.to_boolean(:yes)).must_equal true
      _(klass.to_boolean(:t)).must_equal true
      _(klass.to_boolean(:y)).must_equal true
      _(klass.to_boolean(:'1')).must_equal true
    end

    it 'Symbol false case' do
      _(klass.to_boolean(:false)).must_equal false # rubocop:disable Lint/BooleanSymbol
      _(klass.to_boolean(:no)).must_equal false
      _(klass.to_boolean(:f)).must_equal false
      _(klass.to_boolean(:n)).must_equal false
      _(klass.to_boolean(:'0')).must_equal false
    end

    it 'Symbol nil case' do
      assert_nil(klass.to_boolean(:foo))
    end

    it 'Fixnum true case' do
      _(klass.to_boolean(1)).must_equal true
    end

    it 'Fixnum false case' do
      _(klass.to_boolean(0)).must_equal false
    end

    it 'Fixnum nil case' do
      assert_nil(klass.to_boolean(2))
      assert_nil(klass.to_boolean(-1))
      assert_nil(klass.to_boolean(999))
    end

    it 'TrueClass' do
      _(klass.to_boolean(true)).must_equal true
    end

    it 'FalseClass' do
      _(klass.to_boolean(false)).must_equal false
    end

    it 'NilClass' do
      assert_nil(klass.to_boolean(nil))
    end
  end
end

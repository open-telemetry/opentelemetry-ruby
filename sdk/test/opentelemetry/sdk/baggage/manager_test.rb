# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Baggage::Manager do
  Manager = OpenTelemetry::SDK::Baggage::Manager

  before do
    OpenTelemetry::Context.clear
  end

  describe '.set' do
    it 'sets key/value in baggage' do
      _(Manager.get('foo')).must_be_nil

      Manager.set('foo', 'bar') do
        _(Manager.get('foo')).must_equal('bar')
      end

      _(Manager.get('foo')).must_be_nil
    end
  end

  describe '.with' do
    it 'excutes block with argument as baggage' do
      _(current_baggage).must_be_nil

      Manager.with('foo' => 'bar', 'bar' => 'baz') do
        _(current_baggage).must_equal('foo' => 'bar', 'bar' => 'baz')
      end

      _(current_baggage).must_be_nil
    end
  end

  describe '.clear' do
    it 'excutes block with empty baggage' do
      _(current_baggage).must_be_nil

      Manager.with('foo' => 'bar', 'bar' => 'baz') do
        _(current_baggage).must_equal('foo' => 'bar', 'bar' => 'baz')
        Manager.clear do
          _(current_baggage).must_be(:empty?)
        end
        _(current_baggage).must_equal('foo' => 'bar', 'bar' => 'baz')
      end

      _(current_baggage).must_be_nil
    end
  end

  describe '.remove' do
    it 'excutes block with baggage with key removed' do
      _(current_baggage).must_be_nil

      Manager.with('foo' => 'bar', 'bar' => 'baz') do
        _(current_baggage).must_equal('foo' => 'bar', 'bar' => 'baz')
        Manager.remove('foo') do
          _(current_baggage).must_equal('bar' => 'baz')
        end
        _(current_baggage).must_equal('foo' => 'bar', 'bar' => 'baz')
      end

      _(current_baggage).must_be_nil
    end
  end

  def current_baggage
    OpenTelemetry::Context.get('__baggage__')
  end
end

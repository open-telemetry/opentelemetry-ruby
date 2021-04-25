# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/pg/lru_cache'

describe OpenTelemetry::Instrumentation::PG::LruCache do
  let(:cache) { OpenTelemetry::Instrumentation::PG::LruCache.new(10) }

  it 'can set and retrieve a value' do
    cache['foo'] = 'bar'
    _(cache['foo']).must_equal('bar')
  end

  it 'does not evict keys which were recently read' do
    10.times { |i| cache[i] = i }

    cache[0] # this should cause the '0' key to be the most recently-used
    cache[10] = 10 # As the 11th item, this should cause a cache eviction

    # Because 0 was recently active, it should still be in the cache.
    # 1 should have been the oldest item and should not be present.
    _(cache[0]).must_equal(0)
    _(cache[10]).must_equal(10)
    _(cache[1]).must_be_nil
  end

  it 'does not evict keys which were recently set' do
    10.times { |i| cache[i] = i }
    cache[0] = 0 # this should cause the '0' key to be the most recently-used
    cache[10] = 10 # As the 11th item, this should cause a cache eviction

    # Because 0 was recently active, it should still be in the cache.
    # 1 should have been the oldest item and should not be present.
    _(cache[0]).must_equal(0)
    _(cache[10]).must_equal(10)
    _(cache[1]).must_be_nil
  end

  it 'returns nil if the key is not present' do
    _(cache[:nope]).must_be_nil
  end

  it 'has a fixed size limit' do
    cache = OpenTelemetry::Instrumentation::PG::LruCache.new(1)
    2.times { |i| cache[i] = i }

    _(cache[0]).must_be_nil
    _(cache[1]).must_equal(1)
  end

  it 'disallows invalid size limits' do
    expect do
      OpenTelemetry::Instrumentation::PG::LruCache.new(0)
    end.must_raise ArgumentError
  end
end

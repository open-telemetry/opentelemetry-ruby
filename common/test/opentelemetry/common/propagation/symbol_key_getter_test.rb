# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::Propagation::SymbolKeyGetter do
  let(:symbol_key_getter) { OpenTelemetry::Common::Propagation::SymbolKeyGetter.new }
  let(:carrier) { { foo: 'bar' } }

  describe '#get' do
    it 'retrieves the value' do
      _(symbol_key_getter.get(carrier, 'foo')).must_equal('bar')
    end
  end

  describe '#keys' do
    it 'returns all the keys as strings' do
      _(symbol_key_getter.keys(carrier)).must_equal(['foo'])
    end
  end
end

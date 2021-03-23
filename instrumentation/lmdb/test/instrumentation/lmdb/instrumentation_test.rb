# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/lmdb'

describe OpenTelemetry::Instrumentation::LMDB do
  let(:instrumentation) { OpenTelemetry::Instrumentation::LMDB::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::LMDB'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    after { instrumentation.instance_variable_set(:@installed, false) }

    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end
end

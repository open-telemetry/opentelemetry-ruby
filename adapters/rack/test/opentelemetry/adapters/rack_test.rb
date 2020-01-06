# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/adapters/rack'

describe OpenTelemetry::Adapters::Rack do
  let(:adapter) { OpenTelemetry::Adapters::Rack }

  it 'has #name' do
    _(adapter.name).must_equal 'OpenTelemetry::Adapters::Rack'
  end

  it 'has #version' do
    _(adapter.version).wont_be_nil
    _(adapter.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      adapter.install({})
    end
  end
end

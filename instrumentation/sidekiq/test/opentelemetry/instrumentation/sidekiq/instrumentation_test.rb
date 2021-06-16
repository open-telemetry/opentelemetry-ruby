# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/sidekiq'

describe OpenTelemetry::Instrumentation::Sidekiq::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Sidekiq'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      Gem.stub(:loaded_specs, 'sidekiq' => Gem::Specification.new { |s| s.version = '4.2.8' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end
end

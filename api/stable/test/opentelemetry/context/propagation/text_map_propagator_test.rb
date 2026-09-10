# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::TextMapPropagator do
  let(:context) { OpenTelemetry::Context.empty }
  let(:propagator) do
    OpenTelemetry::Context::Propagation::TextMapPropagator.new(mock_injector, mock_extractor)
  end

  describe 'with working injectors / extractors' do
    let(:mock_injector) do
      Minitest::Mock.new
                    .expect(:inject, {}, [Hash, OpenTelemetry::Context, Context::Propagation::TextMapSetter])
                    .expect(:nil?, false)
    end
    let(:mock_extractor) do
      Minitest::Mock.new
                    .expect(:extract, context, [Hash, OpenTelemetry::Context, Context::Propagation::TextMapGetter])
                    .expect(:nil?, false)
    end

    describe '#inject' do
      it 'delegates to injector' do
        propagator.inject({})
        mock_injector.verify
      end
    end

    describe '#extract' do
      it 'delegates to extractor' do
        propagator.extract({})
        mock_extractor.verify
      end
    end
  end

  describe 'with buggy injectors / extractors' do
    let(:mock_injector) do
      Minitest::Mock.new
                    .expect(:nil?, false)
                    .expect(:inject, {}) { raise 'oops' }
    end
    let(:mock_extractor) do
      Minitest::Mock.new
                    .expect(:nil?, false)
                    .expect(:extract, context) { raise 'oops' }
    end

    describe '#inject' do
      it 'returns carrier' do
        result = {}
        propagator.inject(result)
        _(result).must_equal({})
        mock_injector.verify
      end
    end

    describe '#extract' do
      it 'returns context' do
        result = propagator.extract({}, context: context)
        _(result).must_equal(context)
        mock_extractor.verify
      end
    end
  end
end

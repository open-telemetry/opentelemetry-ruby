# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/graphql'
require_relative '../../../lib/opentelemetry/instrumentation/graphql/tracers/graphql_tracer'

describe OpenTelemetry::Instrumentation::GraphQL do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Remove added tracers
    ::GraphQL::Schema.instance_variable_set(:@own_tracers, [])
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::GraphQL'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'installs the tracer' do
      instrumentation.install({})
      _(::GraphQL::Schema.tracers[0]).must_be_instance_of(OpenTelemetry::Instrumentation::GraphQL::Tracers::GraphQLTracer)
    end
  end
end

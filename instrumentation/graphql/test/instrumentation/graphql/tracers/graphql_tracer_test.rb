# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/graphql'
require_relative '../../../../lib/opentelemetry/instrumentation/graphql/tracers/graphql_tracer'

describe OpenTelemetry::Instrumentation::GraphQL::Tracers::GraphQLTracer do
  let(:graphql_tracer) { OpenTelemetry::Instrumentation::GraphQL::Tracers::GraphQLTracer }
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:config) { {} }

  let(:query_string) do
    <<-GRAPHQL
      query($id: Int!){
        simpleField
        resolvedField(id: $id) {
          originalValue
          uppercasedValue
        }
      }
    GRAPHQL
  end

  before do
    exporter.reset
    instrumentation.install(config)
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Remove added tracers
    ::GraphQL::Schema.instance_variable_set(:@own_tracers, [])
  end

  describe '#platform_trace' do
    it 'traces platform keys' do
      result = SomeGraphQLAppSchema.execute(query_string, variables: { 'id': 1 })

      graphql_tracer.platform_keys.each do |_key, value|
        span = spans.find { |s| s.name == value }
        _(span).wont_be_nil
      end

      _(result.to_h['data']).must_equal('simpleField' => 'Hello.', 'resolvedField' => { 'originalValue' => 'testing=1', 'uppercasedValue' => 'TESTING=1' })
    end

    it 'only traces known platform keys' do
      graphql_tracer.new.trace('unknown_execute_key', nil) {}

      _(spans).must_be(:empty?)
    end

    it 'includes operation attributes for execute_query' do
      expected_attributes = {
        'selected_operation_name' => 'SimpleQuery',
        'selected_operation_type' => 'query',
        'query_string' => 'query SimpleQuery{ simpleField }'
      }

      SomeGraphQLAppSchema.execute('query SimpleQuery{ simpleField }')

      span = spans.find { |s| s.name == 'graphql.execute_query' }
      _(span.attributes.to_h).must_equal(expected_attributes)
    end

    describe 'when platform_field_key is enabled' do
      let(:config) { { enable_platform_field_key: true } }

      it 'traces execute_field' do
        SomeGraphQLAppSchema.execute(query_string, variables: { 'id': 1 })

        span = spans.find { |s| s.name == 'Query.resolvedField' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_authorized_key is enabled' do
      let(:config) { { enable_platform_authorized_key: true } }

      it 'traces .authorized' do
        SomeGraphQLAppSchema.execute(query_string, variables: { 'id': 1 })

        span = spans.find { |s| s.name == 'Query.authorized' }
        _(span).wont_be_nil

        span = spans.find { |s| s.name == 'SlightlyComplex.authorized' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_resolve_type_key is enabled' do
      let(:config) { { enable_platform_resolve_type_key: true } }

      it 'traces .resolve_type' do
        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }')

        span = spans.find { |s| s.name == 'Vehicle.resolve_type' }
        _(span).wont_be_nil
      end
    end
  end

  private

  module Old
    Truck = Struct.new(:price)
  end

  module Vehicle
    include GraphQL::Schema::Interface
  end

  class Car < ::GraphQL::Schema::Object
    implements Vehicle
  end

  class SlightlyComplexType < ::GraphQL::Schema::Object
    field :uppercased_value, String, null: false
    field :original_value, String, null: false

    def uppercased_value
      object.original_value.upcase
    end
  end

  class SimpleResolver < ::GraphQL::Schema::Resolver
    type SlightlyComplexType, null: false

    argument :id, Integer, required: true

    def resolve(id:)
      Struct.new(:original_value).new("testing=#{id}")
    end
  end

  class QueryType < ::GraphQL::Schema::Object
    field :simple_field, String, null: false
    field :resolved_field, resolver: SimpleResolver

    # Required for testing resolve_type
    field :vehicle, Vehicle, null: true

    def vehicle
      Old::Truck.new(50)
    end

    def simple_field
      'Hello.'
    end
  end

  class SomeGraphQLAppSchema < ::GraphQL::Schema
    query(::QueryType)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    orphan_types Car

    def self.resolve_type(_type, _obj, _ctx)
      Car
    end
  end
end

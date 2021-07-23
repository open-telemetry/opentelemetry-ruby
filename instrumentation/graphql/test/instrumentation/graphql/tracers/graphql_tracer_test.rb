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

    # Reset various instance variables to clear state between tests
    ::GraphQL::Schema.instance_variable_set(:@own_tracers, [])

    # Reseting @graphql_definition is needed for tests running against version `1.9.x`
    SomeOtherGraphQLAppSchema.remove_instance_variable(:@graphql_definition) if SomeOtherGraphQLAppSchema.instance_variable_defined?(:@graphql_definition)
    SomeGraphQLAppSchema.remove_instance_variable(:@graphql_definition) if SomeGraphQLAppSchema.instance_variable_defined?(:@graphql_definition)
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
      _(span).wont_be_nil
      _(span.attributes.to_h).must_equal(expected_attributes)
    end

    it 'omits nil attributes for execute_query' do
      expected_attributes = {
        'selected_operation_type' => 'query',
        'query_string' => '{ simpleField }'
      }

      SomeGraphQLAppSchema.execute('{ simpleField }')

      span = spans.find { |s| s.name == 'graphql.execute_query' }
      _(span).wont_be_nil
      _(span.attributes.to_h).must_equal(expected_attributes)
    end

    describe 'when a set of schemas is provided' do
      let(:config) { { schemas: [SomeOtherGraphQLAppSchema] } }

      after do
        # Reset various instance variables to clear state between tests
        SomeOtherGraphQLAppSchema.instance_variable_set(:@own_tracers, [])
        SomeOtherGraphQLAppSchema.instance_variable_set(:@own_plugins, SomeOtherGraphQLAppSchema.plugins[0..1])
      end

      it 'traces the provided schemas' do
        SomeOtherGraphQLAppSchema.execute('query SimpleQuery{ __typename }')

        graphql_tracer.platform_keys.each do |_key, value|
          span = spans.find { |s| s.name == value }
          _(span).wont_be_nil
        end

        _(spans.size).must_equal(8)
      end

      it 'does not trace all schemas' do
        SomeGraphQLAppSchema.execute('query SimpleQuery{ __typename }')

        _(spans).must_be(:empty?)
      end
    end

    describe 'when platform_field is enabled' do
      let(:config) { { enable_platform_field: true } }

      it 'traces execute_field' do
        SomeGraphQLAppSchema.execute(query_string, variables: { 'id': 1 })

        span = spans.find { |s| s.name == 'Query.resolvedField' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_authorized is enabled' do
      let(:config) { { enable_platform_authorized: true } }

      it 'traces .authorized' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute(query_string, variables: { 'id': 1 })

        span = spans.find { |s| s.name == 'Query.authorized' }
        _(span).wont_be_nil

        span = spans.find { |s| s.name == 'SlightlyComplex.authorized' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_resolve_type is enabled' do
      let(:config) { { enable_platform_resolve_type: true } }

      it 'traces .resolve_type' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }')

        span = spans.find { |s| s.name == 'Vehicle.resolve_type' }
        _(span).wont_be_nil
      end
    end

    it 'traces validate with errors' do
      SomeGraphQLAppSchema.execute(
        <<-GRAPHQL
          {
            nonExistentField
          }
        GRAPHQL
      )
      span = spans.find { |s| s.name == 'graphql.validate' }
      error = span.events.find { |e| e.name == 'graphql error' }
      _(error.attributes['error']).must_equal(
        "{\"message\":\"Field 'nonExistentField' doesn't exist on type 'Query'\",\"locations\":[{\"line\":2,\"column\":13}],\"path\":[\"query\",\"nonExistentField\"],\"extensions\":{\"code\":\"undefinedField\",\"typeName\":\"Query\",\"fieldName\":\"nonExistentField\"}}"
      )
    end
  end

  private

  # These fields are only supported as of version 1.10.0
  # https://github.com/rmosolgo/graphql-ruby/blob/v1.10.0/CHANGELOG.md#new-features-1
  def supports_authorized_and_resolved_types?
    Gem.loaded_specs['graphql'].version >= Gem::Version.new('1.10.0')
  end

  module Old
    Truck = Struct.new(:price)
  end

  module Vehicle
    include GraphQL::Schema::Interface
  end

  class Car < ::GraphQL::Schema::Object
    implements Vehicle

    field :price, Integer, null: true
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

  class OtherQueryType < ::GraphQL::Schema::Object
    field :simple_field, String, null: false
    def simple_field
      'Hello.'
    end
  end

  class SomeOtherGraphQLAppSchema < ::GraphQL::Schema
    query(::OtherQueryType)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
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

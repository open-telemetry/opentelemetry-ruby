# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/graphql'
require_relative '../../../../lib/opentelemetry/instrumentation/graphql/patches/opentelemetry_graphql_tracing'

describe OpenTelemetry::Instrumentation::GraphQL::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:root_span) { exporter.finished_spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID } }
  let(:spans) { exporter.finished_spans }

  let(:query_type_name) { 'Query' }
  let(:object_type_name) { 'Foo' }
  let(:object_class) do
    Class.new do
      attr_accessor :id, :name

      def initialize(id, name = 'bar')
        @id = id
        @name = name
      end
    end
  end

  let(:schema) do
    qt = query_type
    Class.new(::GraphQL::Schema) do
      query(qt)
    end
  end

  let(:query_type) do
    qtn = query_type_name
    ot = object_type
    oc = object_class

    Class.new(::GraphQL::Schema::Object) do
      graphql_name qtn
      field ot.graphql_name.downcase, ot, null: false, description: 'Find an object by ID' do
        argument :id, ::GraphQL::Types::ID, required: true
      end

      define_method ot.graphql_name.downcase do |args|
        oc.new(args[:id])
      end
    end
  end

  let(:object_type) do
    otn = object_type_name

    Class.new(::GraphQL::Schema::Object) do
      graphql_name otn
      field :id, ::GraphQL::Types::ID, null: false
      field :name, ::GraphQL::Types::String, null: true
      field :created_at, ::GraphQL::Types::String, null: false
      field :updated_at, ::GraphQL::Types::String, null: false
    end
  end

  let(:schema_define_style) do
    qt = query_type_define_style

    ::GraphQL::Schema.define do
      query(qt)
    end
  end

  let(:query_type_define_style) do
    qtn = query_type_name
    ot = object_type_define_style
    oc = object_class

    ::GraphQL::ObjectType.define do
      graphql_name qtn
      field ot.name.downcase do
        type ot
        argument :id, !types.ID
        description 'Find an object by ID'
        resolve ->(_obj, args, _ctx) { oc.new(args['id']) }
      end
    end
  end

  let(:object_type_define_style) do
    otn = object_type_name

    ::GraphQL::ObjectType.define do
      graphql_name otn
      field :id, !types.ID
      field :name, types.String
      field :created_at, !types.String
      field :updated_at, !types.String
    end
  end

  before do
    exporter.reset
    instrumentation.install(schemas: [schema])
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'query trace' do
    let(:result) { schema.execute(query, variables: {}, context: {}, operation_name: nil) }

    let(:query) { '{ foo(id: 1) { name } }' }
    let(:variables) { {} }
    let(:context) { {} }
    let(:operation_name) { nil }

    it 'before schema executed' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'succcessfully executes query' do
      # Expect no errors
      assert_nil(result.to_h['errors'])

      # Expect nine spans
      _(spans.size).must_equal 9

      # List of valid span names
      # (If this is too brittle, revist later.)
      valid_span_names = [
        'Query.foo',
        'analyze.graphql',
        'execute.graphql',
        'lex.graphql',
        'parse.graphql',
        'validate.graphql'
      ]

      # Expect root span to be 'execute.graphql'
      _(root_span.name).must_equal 'execute.graphql'

      # Expect each span to be properly named
      spans.each do |span|
        _(valid_span_names).must_include(span.name)
      end
    end
  end
end

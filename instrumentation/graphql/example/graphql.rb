# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

dummy_resolve = Class.new do
  attr_accessor :id, :name

  def initialize(id = 1, name = 'bar')
    @id = id
    @name = name
  end
end

EpisodeType = GraphQL::ObjectType.define do
  name 'Episode'
  description 'An episode'
  field :id, !types.ID
  field :name, !types.String
end

QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root of this schema'

  field :episode do
    type EpisodeType
    argument :episode_id, !types.ID
    description 'Find an episode by its ID'
    resolve ->(_obj, args, _ctx) { dummy_resolve.new(args.episode_id) }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
end

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use_all('OpenTelemetry::Instrumentation::GraphQL' => { schemas: [Schema] })
end

result = Schema.execute('{ episode(episode_id: 5) { id name } }', variables: {}, context: {}, operation_name: nil)

puts "episodes are #{result.inspect}"

result

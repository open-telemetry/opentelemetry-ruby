# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/mongo'
require_relative '../../../../../lib/opentelemetry/instrumentation/mongo/middlewares/subscriber'

describe OpenTelemetry::Instrumentation::Mongo::Middlewares::Subscriber do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Mongo::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.first }
  let(:client) { TestHelper.client }
  let(:collection) { :artists }

  before do
    instrumentation.install
    exporter.reset

    TestHelper.setup_mongo

    # this is currently a noop but this will future proof the test
    @orig_propagator = OpenTelemetry.propagation.http
    propagator = OpenTelemetry::Context::Propagation::Propagator.new(
      OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector,
      OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor
    )
    OpenTelemetry.propagation.http = propagator
  end

  after do
    OpenTelemetry.propagation.http = @orig_propagator

    TestHelper.teardown_mongo
  end

  module MongoTraceTest
    it 'has basic properties' do
      _(spans.size).must_equal 1
      _(span.attributes['component']).must_equal 'mongo-ruby'
      _(span.attributes['db.type']).must_equal 'mongodb'
      _(span.attributes['db.instance']).must_equal TestHelper.database
      _(span.attributes['mongo.request_id']).must_be_kind_of Integer
      _(span.attributes['mongo.op_id']).must_be_kind_of Integer
      _(span.attributes['peer.hostname']).must_equal TestHelper.host
      _(span.attributes['peer.port']).must_equal TestHelper.port
    end
  end

  describe '#insert_one operation' do
    before { client[collection].insert_one(params) }

    describe 'for a basic document' do
      let(:params) { { name: 'FKA Twigs' } }

      include MongoTraceTest

      it 'has operation-specific properties' do
        _(span.attributes['mongo.command']).must_equal 'insert'
        _(span.attributes['mongo.collection']).must_equal 'artists'
        _(span.attributes['db.statement']).must_equal nil
        _(span.attributes['mongo.n']).must_equal 1
      end
    end

    describe 'for a document with an array' do
      let(:params) { { name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'] } }
      let(:collection) { :people }

      include MongoTraceTest

      it 'has operation-specific properties' do
        _(span.attributes['mongo.command']).must_equal 'insert'
        _(span.attributes['mongo.collection']).must_equal 'people'
        _(span.attributes['db.statement']).must_equal nil
        _(span.attributes['mongo.n']).must_equal 1
      end
    end
  end

  describe '#insert_many operation' do
    before { client[collection].insert_many(params) }

    describe 'for documents with arrays' do
      let(:params) do
        [
          { name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'] },
          { name: 'Sally', hobbies: ['skiing', 'stamp collecting'] }
        ]
      end

      let(:collection) { :people }

      include MongoTraceTest

      it 'has operation-specific properties' do
        _(span.attributes['mongo.command']).must_equal 'insert'
        _(span.attributes['mongo.collection']).must_equal 'people'
        _(span.attributes['db.statement']).must_equal nil
        _(span.attributes['mongo.n']).must_equal 2
      end
    end
  end

  describe '#find_all operation' do
    let(:collection) { :people }

    before do
      # Insert a document
      client[collection].insert_one(name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'])
      exporter.reset

      # Do #find_all operation
      client[collection].find.each do |document|
        # =>  Yields a BSON::Document.
      end
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'find'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal nil
      _(span.attributes['mongo.n']).must_equal nil
    end
  end

  describe '#find operation' do
    let(:collection) { :people }

    before do
      # Insert a document
      client[collection].insert_one(name: 'Steve', hobbies: ['hiking'])
      exporter.reset

      # Do #find operation
      result = client[collection].find(name: 'Steve').first[:hobbies]
      _(result).must_equal ['hiking']
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'find'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"filter":{"name":"?"}}'
      _(span.attributes['mongo.n']).must_equal nil
    end
  end

  describe '#update_one operation' do
    let(:collection) { :people }

    before do
      # Insert a document
      client[collection].insert_one(name: 'Sally', hobbies: ['skiing', 'stamp collecting'])
      exporter.reset

      # Do #update_one operation
      client[collection].update_one({ name: 'Sally' }, '$set' => { 'phone_number' => '555-555-5555' })
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'update'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"updates":[{"q":{"name":"?"},"u":{"$set":{"phone_number":"?"}}}]}'
      _(span.attributes['mongo.n']).must_equal 1
    end

    it 'correctly performs operation' do
      _(client[collection].find(name: 'Sally').first[:phone_number]).must_equal '555-555-5555'
    end
  end

  describe '#update_many operation' do
    let(:collection) { :people }
    let(:documents) do
      [
        { name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'] },
        { name: 'Sally', hobbies: ['skiing', 'stamp collecting'] }
      ]
    end

    before do
      # Insert documents
      client[collection].insert_many(documents)
      exporter.reset

      # Do #update_many operation
      client[collection].update_many({}, '$set' => { 'phone_number' => '555-555-5555' })
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'update'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"updates":[{"u":{"$set":{"phone_number":"?"}},"multi":true}]}'
      _(span.attributes['mongo.n']).must_equal 2
    end

    it 'correctly performs operation' do
      documents.each do |d|
        _(client[collection].find(name: d[:name]).first[:phone_number]).must_equal '555-555-5555'
      end
    end
  end

  describe '#delete_one operation' do
    let(:collection) { :people }

    before do
      # Insert a document
      client[collection].insert_one(name: 'Sally', hobbies: ['skiing', 'stamp collecting'])
      exporter.reset

      # Do #delete_one operation
      client[collection].delete_one(name: 'Sally')
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'delete'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"deletes":[{"q":{"name":"?"}}]}'
      _(span.attributes['mongo.n']).must_equal 1
    end

    it 'correctly performs operation' do
      _(client[collection].find(name: 'Sally').count).must_equal 0
    end
  end

  describe '#delete_many operation' do
    let(:collection) { :people }
    let(:documents) do
      [
        { name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'] },
        { name: 'Sally', hobbies: ['skiing', 'stamp collecting'] }
      ]
    end

    before do
      # Insert documents
      client[collection].insert_many(documents)
      exporter.reset

      # Do #delete_many operation
      client[collection].delete_many(name: /$S*/)
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'delete'
      _(span.attributes['mongo.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"deletes":[{"q":{"name":"?"}}]}'
      _(span.attributes['mongo.n']).must_equal 2
    end

    it 'correctly performs operation' do
      documents.each do |d|
        _(client[collection].find(name: d[:name]).count).must_equal 0
      end
    end
  end

  describe '#drop operation' do
    let(:collection) { 1 } # Because drop operation doesn't have a collection

    before { client.database.drop }

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'dropDatabase'
      _(span.attributes['mongo.collection']).must_equal nil
      _(span.attributes['db.statement']).must_equal nil
      _(span.attributes['mongo.n']).must_equal nil
    end
  end

  describe 'a failed query' do
    before { client[:artists].drop }

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.attributes['mongo.command']).must_equal 'drop'
      _(span.attributes['mongo.collection']).must_equal 'artists'
      _(span.attributes['db.statement']).must_equal nil
      _(span.attributes['mongo.n']).must_equal nil
      _(span.attributes['error']).must_equal true
      _(span.attributes['error.kind']).must_equal 'CommandFailed'
      _(span.attributes['message']).must_equal 'ns not found (26)'
    end

    describe 'that triggers #failed before #started' do
      let(:subscriber) { OpenTelemetry::Instrumentation::Mongo::Middlewares::Subscriber.new }
      let(:failed_event) { subscriber.failed(event) }
      let(:event) { instance_double(Mongo::Monitoring::Event::CommandFailed, request_id: double('request_id')) }

      it 'does not raise error even when thread is cleared' do
        Thread.current[:__opentelemetry_mongo_spans__] = nil
        failed_event
      end
    end
  end

  describe 'with LDAP/SASL authentication' do
    let(:client) { Mongo::Client.new(["#{TestHelper.host}:#{TestHelper.port}"], client_options) }
    let(:client_options) do
      { database: TestHelper.database,
        auth_mech: :plain,
        user: 'plain_user',
        password: 'plain_pass' }
    end

    describe 'which fails' do
      before do
        client[collection].insert_one(name: 'Steve', hobbies: ['hiking'])
      rescue Mongo::Auth::Unauthorized
        nil
      end

      it 'produces spans for command and authentication' do
        _(spans.size).must_equal 1
        _(span.name).must_equal 'mongo.cmd'
        _(span.attributes['mongo.command']).must_equal 'saslStart'
        _(span.attributes['error']).must_equal true
        _(span.attributes['error.kind']).must_equal 'CommandFailed'
        _(span.attributes['message']).must_match(/Unsupported mechanism.+PLAIN.+\(2\)/)
      end
    end
  end
end

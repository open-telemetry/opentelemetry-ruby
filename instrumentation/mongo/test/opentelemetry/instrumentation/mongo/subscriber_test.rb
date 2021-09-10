# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../lib/opentelemetry/instrumentation/mongo'
require_relative '../../../../lib/opentelemetry/instrumentation/mongo/subscriber'

describe OpenTelemetry::Instrumentation::Mongo::Subscriber do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Mongo::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.first }
  let(:client) { TestHelper.client }
  let(:collection) { :artists }
  let(:config) { {} }

  before do
    # Clear previous instrumentation subscribers between test runs
    Mongo::Monitoring::Global.subscribers['Command'] = []
    instrumentation.install(config)
    exporter.reset

    TestHelper.setup_mongo

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
    OpenTelemetry.propagation = @orig_propagation
    TestHelper.teardown_mongo
  end

  module MongoTraceTest
    it 'has basic properties' do
      _(spans.size).must_equal 1
      _(span.attributes['db.system']).must_equal 'mongodb'
      _(span.attributes['db.name']).must_equal TestHelper.database
      _(span.attributes['net.peer.name']).must_equal TestHelper.host
      _(span.attributes['net.peer.port']).must_equal TestHelper.port
    end
  end

  describe '#insert_one operation' do
    before { client[collection].insert_one(params) }

    describe 'for a basic document' do
      let(:params) { { name: 'FKA Twigs' } }

      include MongoTraceTest

      it 'has operation-specific properties' do
        _(span.name).must_equal 'artists.insert'
        _(span.attributes['db.operation']).must_equal 'insert'
        _(span.attributes['db.mongodb.collection']).must_equal 'artists'
        refute(span.attributes.key?('db.statement'))
      end
    end

    describe 'for a document with an array' do
      let(:params) { { name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'] } }
      let(:collection) { :people }

      include MongoTraceTest

      it 'has operation-specific properties' do
        _(span.name).must_equal 'people.insert'
        _(span.attributes['db.operation']).must_equal 'insert'
        _(span.attributes['db.mongodb.collection']).must_equal 'people'
        refute(span.attributes.key?('db.statement'))
      end
    end
  end

  describe 'when peer service has been set in config' do
    let(:params) { { name: 'FKA Twigs' } }
    let(:config) { { peer_service: 'example:mongo' } }

    include MongoTraceTest

    before do
      client[collection].insert_one(params)
    end

    it 'includes it in the span attributes' do
      _(span.attributes['peer.service']).must_equal 'example:mongo'
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
        _(span.name).must_equal 'people.insert'
        _(span.attributes['db.operation']).must_equal 'insert'
        _(span.attributes['db.mongodb.collection']).must_equal 'people'
        refute(span.attributes.key?('db.statement'))
      end
    end
  end

  describe '#find_all operation' do
    let(:collection) { :people }

    before do
      # insert a document
      client[collection].insert_one(name: 'Steve', hobbies: ['hiking', 'tennis', 'fly fishing'])
      exporter.reset

      # do #find_all operation
      client[collection].find.each do |document|
        # => yields a BSON::Document.
      end
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.find'
      _(span.attributes['db.operation']).must_equal 'find'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      refute(span.attributes.key?('db.statement'))
    end
  end

  describe '#find operation' do
    let(:collection) { :people }

    before do
      # insert a document
      client[collection].insert_one(name: 'Steve', hobbies: ['hiking'])
      exporter.reset

      # do #find operation
      result = client[collection].find(name: 'Steve').first[:hobbies]
      _(result).must_equal ['hiking']
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.find'
      _(span.attributes['db.operation']).must_equal 'find'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"filter":{"name":"?"}}'
    end
  end

  describe '#update_one operation' do
    let(:collection) { :people }

    before do
      # insert a document
      client[collection].insert_one(name: 'Sally', hobbies: ['skiing', 'stamp collecting'])
      exporter.reset

      # do #update_one operation
      client[collection].update_one({ name: 'Sally' }, '$set' => { 'phone_number' => '555-555-5555' })
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.update'
      _(span.attributes['db.operation']).must_equal 'update'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"updates":[{"q":{"name":"?"},"u":{"$set":{"phone_number":"?"}}}]}'
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
      # insert documents
      client[collection].insert_many(documents)
      exporter.reset

      # do #update_many operation
      client[collection].update_many({}, '$set' => { 'phone_number' => '555-555-5555' })
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.update'
      _(span.attributes['db.operation']).must_equal 'update'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"updates":[{"u":{"$set":{"phone_number":"?"}},"multi":true}]}'
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
      # insert a document
      client[collection].insert_one(name: 'Sally', hobbies: ['skiing', 'stamp collecting'])
      exporter.reset

      # do #delete_one operation
      client[collection].delete_one(name: 'Sally')
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.delete'
      _(span.attributes['db.operation']).must_equal 'delete'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"deletes":[{"q":{"name":"?"}}]}'
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
      # insert documents
      client[collection].insert_many(documents)
      exporter.reset

      # do #delete_many operation
      client[collection].delete_many(name: /$S*/)
    end

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'people.delete'
      _(span.attributes['db.operation']).must_equal 'delete'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes['db.statement']).must_equal '{"deletes":[{"q":{"name":"?"}}]}'
    end

    it 'correctly performs operation' do
      documents.each do |d|
        _(client[collection].find(name: d[:name]).count).must_equal 0
      end
    end
  end

  describe '#drop operation' do
    let(:collection) { 1 } # because drop operation doesn't have a collection

    before { client.database.drop }

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'dropDatabase'
      _(span.attributes['db.operation']).must_equal 'dropDatabase'
      refute(span.attributes.key?('db.mongodb.collection'))
      refute(span.attributes.key?('db.statement'))
    end
  end

  describe 'db_statement option' do
    let(:collection) { :people }
    let(:config) { { db_statement: :omit } }

    before do
      # insert a document
      client[collection].insert_one(name: 'Steve', hobbies: ['hiking'])
      exporter.reset

      # do #find operation
      result = client[collection].find(name: 'Steve').first[:hobbies]
      _(result).must_equal ['hiking']
    end

    it 'omits db.statement attribute' do
      _(span.name).must_equal 'people.find'
      _(span.attributes['db.operation']).must_equal 'find'
      _(span.attributes['db.mongodb.collection']).must_equal 'people'
      _(span.attributes).wont_include 'db.statement'
    end
  end

  describe 'a failed query' do
    before { client[:artists].drop }

    include MongoTraceTest

    it 'has operation-specific properties' do
      _(span.name).must_equal 'artists.drop'
      _(span.attributes['db.operation']).must_equal 'drop'
      _(span.attributes['db.mongodb.collection']).must_equal 'artists'
      refute(span.attributes.key?('db.statement'))
      _(span.events.size).must_equal 1
      _(span.events[0].name).must_equal 'exception'
      _(span.events[0].timestamp).must_be_kind_of Integer
      _(span.events[0].attributes['exception.type']).must_equal 'CommandFailed'
      _(span.events[0].attributes['exception.message']).must_equal 'ns not found (26)'
    end

    describe 'that triggers #failed before #started' do
      let(:subscriber) { OpenTelemetry::Instrumentation::Mongo::Subscriber.new }
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
      {
        database: TestHelper.database,
        auth_mech: :plain,
        user: 'plain_user',
        password: 'plain_pass'
      }
    end

    describe 'which fails' do
      before do
        client[collection].insert_one(name: 'Steve', hobbies: ['hiking'])
      rescue Mongo::Auth::Unauthorized
        nil
      end

      it 'produces spans for command and authentication' do
        _(spans.size).must_equal 1
        _(span.name).must_equal 'saslStart'
        _(span.attributes['db.operation']).must_equal 'saslStart'
        _(span.events.size).must_equal 1
        _(span.events[0].name).must_equal 'exception'
        _(span.events[0].timestamp).must_be_kind_of Integer
        _(span.events[0].attributes['exception.type']).must_equal 'CommandFailed'
        _(span.events[0].attributes['exception.message']).must_match(/mechanism.+PLAIN./)
      end
    end
  end
end unless ENV['OMIT_SERVICES']

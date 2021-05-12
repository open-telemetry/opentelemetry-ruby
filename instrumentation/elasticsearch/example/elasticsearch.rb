# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'elasticsearch'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Elasticsearch'
end

client = Elasticsearch::Client.new log: true

client.transport.reload_connections!

client.cluster.health

client.indices.create(index: 'traces') unless client.indices.exists(index: 'traces')

client.search q: 'test'

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mongo'
end

client = Mongo::Client.new(['127.0.0.1:27017'], database: 'otel_test')

client['people'].insert_one(name: 'Steve', hobbies: ['hiking'])

client['people'].find(name: 'Steve').first

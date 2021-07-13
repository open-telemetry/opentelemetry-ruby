# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'bunny'

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Bunny'
end

# Start a communication session with RabbitMQ
conn = Bunny.new
conn.start

# open a channel
ch = conn.create_channel

# declare a queue
q  = ch.queue('opentelemetry-ruby-demonstration')

# publish a message to the default exchange which then gets routed to this queue
q.publish('Hello, opentelemetry!')

# fetch a message from the queue
q.pop do |delivery_info, metadata, payload|
  puts "Message: #{payload}"
  puts "Delivery info: #{delivery_info}"
  puts "Metadata: #{metadata}"
end

# close the connection
conn.stop

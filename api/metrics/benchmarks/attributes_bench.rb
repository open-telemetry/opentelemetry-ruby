# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

ATTRS_NONE   = {}.freeze
ATTRS_SMALL  = { 'env' => 'prod' }.freeze
ATTRS_MEDIUM = { 'http.method' => 'GET', 'http.status_code' => 200, 'http.route' => '/api/users' }.freeze
ATTRS_LARGE  = {
  'http.method' => 'GET',
  'http.status_code' => 200,
  'http.route' => '/api/users',
  'net.host.name' => 'example.com',
  'net.host.port' => 443,
  'http.scheme' => 'https',
  'http.flavor' => '1.1',
  'http.user_agent' => 'Ruby/3.3'
}.freeze

puts "\n#{'=' * 60}"
puts '= Attribute cardinality (SDK counter)'
puts '=' * 60

card_counter = build_sdk_meter.create_counter('bench.cardinality.counter')

Benchmark.ips do |x|
  x.report('counter#add (no attrs)')     { card_counter.add(1, attributes: ATTRS_NONE) }
  x.report('counter#add (small attrs)')  { card_counter.add(1, attributes: ATTRS_SMALL) }
  x.report('counter#add (medium attrs)') { card_counter.add(1, attributes: ATTRS_MEDIUM) }
  x.report('counter#add (large attrs)')  { card_counter.add(1, attributes: ATTRS_LARGE) }
  x.compare!
end

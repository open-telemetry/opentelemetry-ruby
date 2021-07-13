# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::PG', enable_sql_obfuscation: true
end

conn = PG::Connection.open(
  host: ENV.fetch('TEST_POSTGRES_HOST') { '127.0.0.1' },
  port: ENV.fetch('TEST_POSTGRES_PORT') { '5432' },
  user: ENV.fetch('TEST_POSTGRES_USER') { 'postgres' },
  dbname: ENV.fetch('TEST_POSTGRES_DB') { 'postgres' },
  password: ENV.fetch('TEST_POSTGRES_PASSWORD') { 'postgres' }
)

# Spans will be printed to your terminal when this statement executes:
conn.exec('SELECT 1 AS a, 2 AS b, NULL AS c').each_row { |r| puts r.inspect }

# You can use parameterized queries like so:
# conn.exec_params('SELECT $1 AS a, $2 AS b, $3 AS c', [1, 2, nil]).each_row { |r| puts r.inspect }

# And, you can prepare statements and execute them like this:
# conn.prepare('foo', 'SELECT $1 AS a, $2 AS b, $3 AS c')
# conn.exec_prepared('foo', [1, 2, nil])

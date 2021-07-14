# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mysql2'
end

client = Mysql2::Client.new(
  host: ENV.fetch('TEST_MYSQL_HOST') { '127.0.0.1' },
  port: ENV.fetch('TEST_MYSQL_PORT') { '3306' },
  database: ENV.fetch('TEST_MYSQL_DB') { 'mysql' },
  username: ENV.fetch('TEST_MYSQL_USER') { 'root' },
  password: ENV.fetch('TEST_MYSQL_PASSWORD') { 'root' }
)

client.query("SELECT * FROM users WHERE group='x'")

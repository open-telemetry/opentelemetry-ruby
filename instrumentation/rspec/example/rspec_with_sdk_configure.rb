# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'rspec/autorun'

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RSpec'
end

require_relative '../lib/opentelemetry/instrumentation/rspec/formatter'

RSpec.configure do |config|
  config.formatter = OpenTelemetry::Instrumentation::RSpec::Formatter
end

RSpec.describe OpenTelemetry::Instrumentation::RSpec::Formatter do
  describe 'when configured' do
    it 'exports spans when configured as a formatter' do
      tracer = OpenTelemetry.tracer_provider.tracer('default')
      tracer.in_span('trace inside example') do
        expect(true).to eql false
      end
    end
  end
end

# frozen_string_literal: true

require 'rubygems'
require 'active_support'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveSupport'
end

tracer = OpenTelemetry.tracer_provider.tracer('my_app_or_gem', '0.1.0')

::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(tracer, 'bar.foo')

::ActiveSupport::Notifications.instrument('bar.foo', extra: 'context')

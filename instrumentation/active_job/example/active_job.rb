# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'
require 'active_job'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
end

class TestJob < ::ActiveJob::Base
  def perform
    puts <<~EOS

    --------------------------------------------------
     The computer is doing some work, beep beep boop.
    --------------------------------------------------

    EOS
  end
end

::ActiveJob::Base.queue_adapter = :async

TestJob.perform_later
sleep 0.1 # To ensure we see both spans!

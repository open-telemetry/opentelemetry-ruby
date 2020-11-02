# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::DelayedJob'
end

# A basic Delayed Job worker example
payload = Class.new do
  def perform
    puts "Workin'"
  end
end

job = Delayed::Job.enqueue(payload.new)

Delayed::Worker.new.run(job)

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::AwsSdk', suppress_internal_instrumentation: false
end

sns = Aws::SNS::Client.new
sns.publish message: 'ruby sending message to sns'

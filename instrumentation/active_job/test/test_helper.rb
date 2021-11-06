# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'active_job'
require 'opentelemetry-instrumentation-active_job'
require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'webmock/minitest'

require 'pry'

class TestJob < ::ActiveJob::Base
  def perform; end
end

class RetryJob < ::ActiveJob::Base
  retry_on StandardError, wait: 0, attempts: 2

  def perform
    raise StandardError
  end
end

class ExceptionJob < ::ActiveJob::Base
  def perform
    raise StandardError, 'This job raises an exception'
  end
end

class BaggageJob < ::ActiveJob::Base
  def perform
    OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class PositionalOnlyArgsJob < ::ActiveJob::Base
  def perform(arg1, arg2 = 'default'); end
end
class KeywordOnlyArgsJob < ::ActiveJob::Base
  def perform(keyword1: 'default', keyword2:); end
end

class MixedArgsJob < ::ActiveJob::Base
  def perform(arg1, arg2, keyword1: 'default', keyword2:); end
end

::ActiveJob::Base.queue_adapter = :inline
::ActiveJob::Base.logger = Logger.new(File::NULL)

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  c.add_span_processor span_processor
end

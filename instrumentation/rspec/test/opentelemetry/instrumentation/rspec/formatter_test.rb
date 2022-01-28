# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/rspec/formatter'

describe OpenTelemetry::Instrumentation::RSpec::Formatter do
  before(:each) do
    EXPORTER.reset
  end

  def run_rspec_configured_with_otel_formatter(formatter = OpenTelemetry::Instrumentation::RSpec::Formatter)
    options = RSpec::Core::ConfigurationOptions.new([])

    configuration = RSpec::Core::Configuration.new

    runner = RSpec::Core::Runner.new(options, configuration, RSpec::Core::World.new)
    runner.configuration.formatter = formatter
    yield runner if block_given?
  end

  def run_rspec_with_tracing
    run_rspec_configured_with_otel_formatter do |runner|
      groups = yield
      runner.run_specs(Array(groups))
    end
    spans = EXPORTER.finished_spans
    EXPORTER.reset
    spans
  end

  it 'exports spans for suites' do
    spans = run_rspec_with_tracing do
      group_string = RSpec.describe(String) do
        example('example string') {}
      end
      group_one = RSpec.describe('group one') do
        example('example one') {}
      end
      group_two = RSpec.describe('group two') do
        example('example two') {}
      end
      [group_string, group_one, group_two]
    end
    _(spans.map(&:name)).must_equal ['example string', 'String', 'example one', 'group one', 'example two', 'group two', 'RSpec suite']
  end

  it 'will not be affected by tests that mock time' do
    current_time = Time.now
    Time.stub(:now, Time.at(0)) do
      spans = run_rspec_with_tracing do
        RSpec.describe('group one') do
          example('example one') { expect(Time.now).to eq Time.at(0) }
        end
      end
      _(spans.first.name).must_equal 'example one'
      _(spans.first.attributes['rspec.example.result']).must_equal 'passed'
      _(spans.first.start_timestamp).wont_equal 0
      _(spans.first.start_timestamp / 1_000_000_000).must_be_close_to(current_time.to_i)
      _(spans.first.end_timestamp / 1_000_000_000).must_be_close_to(current_time.to_i)
    end
  end

  describe 'exports spans for example groups' do
    it 'describes the class if specified' do
      spans = run_rspec_with_tracing do
        RSpec.describe(String) do
          describe('group description') do
            example('example one') {}
          end
        end
      end
      _(spans.map(&:name)).must_equal ['example one', 'group description', 'String', 'RSpec suite']
    end

    it 'describes the group description if specified' do
      spans = run_rspec_with_tracing do
        RSpec.describe('group description') do
          example('example one') {}
        end
      end
      _(spans.map(&:name)).must_equal ['example one', 'group description', 'RSpec suite']
    end

    it 'passes context onto child spans' do
      spans = run_rspec_with_tracing do
        RSpec.describe('group one') do
          example('example one') do
            expect(true).to equal true
          end
        end
      end
      example_span = spans[0]
      _(example_span.name).must_equal('example one')
      group_span = spans[1]
      _(group_span.name).must_equal('group one')
      _(example_span.hex_parent_span_id).must_equal(group_span.hex_span_id)
    end
  end

  describe 'exports spans for examples' do
    def run_example(&blk)
      spans = run_rspec_with_tracing do
        RSpec.describe('group one') do
          instance_eval(&blk)
        end
      end
      spans.first
    end

    describe 'that pass' do
      subject do
        run_example do
          example('example one') {}
        end
      end

      it 'has a name that matches the example description' do
        _(subject.name).must_equal 'example one'
      end

      it 'has a description attribute matches the full example description' do
        _(subject.attributes['rspec.example.full_description']).must_equal 'group one example one'
      end

      it 'has a description attribute matches the full example description' do
        _(subject.attributes['rspec.example.location']).must_match %r{\./test/opentelemetry/instrumentation/rspec/formatter_test.rb:\d+}
      end

      it 'records when the example passes' do
        _(subject.attributes['rspec.example.result']).must_equal 'passed'
      end
    end

    it 'passes context onto child spans' do
      spans = run_rspec_with_tracing do
        RSpec.describe('group one') do
          example('example one') do
            OpenTelemetry.tracer_provider.tracer('example child span').in_span('child span') do
              expect(true).to equal true
            end
          end
        end
      end
      child = spans[0]
      example_span = spans[1]
      _(child.name).must_equal('child span')
      _(example_span.name).must_equal('example one')
      _(child.hex_parent_span_id).must_equal(example_span.hex_span_id)
    end

    describe 'that fail' do
      subject do
        run_example do
          example('example one') { expect(true).to eql false }
        end
      end

      it 'records when the example fails' do
        _(subject.attributes['rspec.example.result']).must_equal 'failed'
      end

      it 'records the span status as error' do
        _(subject.status.ok?).must_equal false
        _(subject.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end

      it 'records the failure message' do
        message = <<~MESSAGE.rstrip

          expected: false
               got: true

          (compared using eql?)

          Diff:\e[0m
          \e[0m\e[34m@@ -1 +1 @@
          \e[0m\e[31m-false
          \e[0m\e[32m+true
          \e[0m
        MESSAGE
        _(subject.attributes['rspec.example.failure_message']).must_equal message
        _(subject.status.description).must_equal message
        _(subject.events.first.attributes['exception.message']).must_equal message
      end

      it 'records the exception' do
        _(subject.events.first.attributes['exception.type']).must_equal 'RSpec::Expectations::ExpectationNotMetError'
      end
    end

    describe 'that error' do
      subject do
        run_example do
          example('example one') { raise 'my-error-message' }
        end
      end

      it 'records when the example fails' do
        _(subject.attributes['rspec.example.result']).must_equal 'failed'
      end

      it 'records the span status as error' do
        _(subject.status.ok?).must_equal false
        _(subject.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end

      it 'records the exception' do
        _(subject.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end

      it 'records the exception' do
        _(subject.events.first.attributes['exception.message']).must_equal 'my-error-message'
      end
    end
  end
  describe 'using a custom tracer provider' do
    describe 'with the formatter' do
      it 'will sends spans to the connected exporter' do
        exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
        span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
        tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
        tracer_provider.add_span_processor(span_processor)
        formatter = OpenTelemetry::Instrumentation::RSpec::Formatter.new(StringIO.new, tracer_provider)
        run_rspec_configured_with_otel_formatter(formatter) do |runner|
          group_string = RSpec.describe(String) do
            example('example string') {}
          end
          runner.run_specs([group_string])
        end
        spans = exporter.finished_spans
        _(spans.map(&:name)).must_equal ['example string', 'String', 'RSpec suite']
        _(EXPORTER.finished_spans).must_equal []
      end

      it 'will sends spans to the connected exporter' do
        exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
        span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
        tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
        tracer_provider.add_span_processor(span_processor)
        tracer = tracer_provider.tracer('foo')

        spans = run_rspec_with_tracing do
          group_one = RSpec.describe('group one') do
            example('example one') do
              tracer.in_span('my first test span')
            end
          end
          group_string = RSpec.describe(String) do
            example('example string') do
              tracer.in_span('my second test span')
            end
          end
          [group_one, group_string]
        end
        _(exporter.finished_spans.map(&:name)).must_equal ['my first test span', 'my second test span']
        _(spans.map(&:name)).must_equal ['example one', 'group one', 'example string', 'String', 'RSpec suite']
      end
    end
  end
end

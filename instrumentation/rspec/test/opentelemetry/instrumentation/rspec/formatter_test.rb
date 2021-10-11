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

  def run_rspec_configured_with_otel_formatter
    options = RSpec::Core::ConfigurationOptions.new([])

    configuration = RSpec::Core::Configuration.new

    runner = RSpec::Core::Runner.new(options, configuration, RSpec::Core::World.new)
    runner.configuration.formatter = OpenTelemetry::Instrumentation::RSpec::Formatter
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
        _(subject.attributes['full_description']).must_equal 'group one example one'
      end

      it 'has a description attribute matches the full example description' do
        _(subject.attributes['location']).must_match %r{\./test/opentelemetry/instrumentation/rspec/formatter_test.rb:\d+}
      end

      it 'records when the example passes' do
        _(subject.attributes['result']).must_equal 'passed'
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
        _(subject.attributes['result']).must_equal 'failed'
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
        _(subject.attributes['message']).must_equal message
      end

      it 'records the exception' do
        assert_nil(subject.attributes['exception.type'])
      end
    end

    describe 'that error' do
      subject do
        run_example do
          example('example one') { raise 'my-error-message' }
        end
      end

      it 'records when the example fails' do
        _(subject.attributes['result']).must_equal 'failed'
      end

      it 'records the exception' do
        _(subject.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end

      it 'records the exception' do
        _(subject.events.first.attributes['exception.message']).must_equal 'my-error-message'
      end
    end
  end
end

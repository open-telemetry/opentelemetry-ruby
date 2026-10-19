# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Meter do
  before { OpenTelemetry::SDK.configure }

  let(:meter) { OpenTelemetry.meter_provider.meter('new_meter') }

  describe 'instrumentation scope attributes' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }

    before do
      reset_metrics_sdk
      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
    end

    it 'creates a meter with empty attributes by default' do
      OpenTelemetry.meter_provider.meter('test').create_counter('a_counter').add(1)

      metric_exporter.pull
      _(metric_exporter.metric_snapshots[0].instrumentation_scope.attributes).must_equal({})
    end

    it 'normalizes nil attributes to empty hash' do
      OpenTelemetry.meter_provider.meter('test', attributes: nil).create_counter('a_counter').add(1)

      metric_exporter.pull
      _(metric_exporter.metric_snapshots[0].instrumentation_scope.attributes).must_equal({})
    end

    it 'creates a meter with attributes' do
      attrs = { 'key' => 'value' }
      OpenTelemetry.meter_provider.meter('test', attributes: attrs).create_counter('a_counter').add(1)

      metric_exporter.pull
      _(metric_exporter.metric_snapshots[0].instrumentation_scope.attributes).must_equal(attrs)
    end

    it 'propagates attributes through to exported metric data' do
      attrs = { 'key' => 'value' }
      OpenTelemetry.meter_provider.meter('test', version: '1.0', attributes: attrs).create_counter('a_counter').add(1)

      metric_exporter.pull
      snapshot = metric_exporter.metric_snapshots[0]
      _(snapshot.instrumentation_scope.name).must_equal('test')
      _(snapshot.instrumentation_scope.version).must_equal('1.0')
      _(snapshot.instrumentation_scope.attributes).must_equal(attrs)
    end
  end

  describe '#create_counter' do
    it 'creates a counter instrument' do
      instrument = meter.create_counter('a_counter', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Counter
    end
  end

  describe '#create_histogram' do
    it 'creates a histogram instrument' do
      instrument = meter.create_histogram('a_histogram', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Histogram
    end
  end

  describe '#create_up_down_counter' do
    it 'creates a up_down_counter instrument' do
      instrument = meter.create_up_down_counter('a_up_down_counter', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::UpDownCounter
    end
  end

  describe '#create_observable_counter' do
    it 'creates a observable_counter instrument' do
      instrument = meter.create_observable_counter('a_observable_counter', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter
    end
  end

  describe '#create_observable_gauge' do
    it 'creates a observable_gauge instrument' do
      instrument = meter.create_observable_gauge('a_observable_gauge', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'creates a observable_up_down_counter instrument' do
      instrument = meter.create_observable_up_down_counter('a_observable_up_down_counter', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter
    end
  end

  describe 'callback' do
    describe '#register_callback' do
      let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
      let(:meter) { OpenTelemetry.meter_provider.meter('test') }

      before do
        reset_metrics_sdk
        OpenTelemetry::SDK.configure
        OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

        @original_temp = ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', nil)
        ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'] = 'delta'
      end

      after do
        ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'] = @original_temp
      end

      it 'create callback with multi asychronous instrument' do
        callback_first = proc { 10 }
        counter_first  = meter.create_observable_counter('counter_first', unit: 'smidgen', description: '', callback: callback_first)
        counter_second = meter.create_observable_counter('counter_second', unit: 'smidgen', description: '', callback: callback_first)

        callback_second = proc { 20 }
        meter.register_callback([counter_first, counter_second], callback_second)

        _(counter_first.instance_variable_get(:@callbacks).size).must_equal 2
        _(counter_second.instance_variable_get(:@callbacks).size).must_equal 2

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(30)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(30)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)
      end

      it 'remove callback with multi asychronous instrument' do
        callback_first = proc { 10 }
        counter_first  = meter.create_observable_counter('counter_first', unit: 'smidgen', description: '', callback: callback_first)
        counter_second = meter.create_observable_counter('counter_second', unit: 'smidgen', description: '', callback: callback_first)

        callback_second = proc { 20 }
        meter.register_callback([counter_first, counter_second], callback_second)

        _(counter_first.instance_variable_get(:@callbacks).size).must_equal 2
        _(counter_second.instance_variable_get(:@callbacks).size).must_equal 2

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(30)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(30)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)

        # unregister the callback_second from instruments counter_first and counter_second
        meter.unregister([counter_first, counter_second], callback_second)

        metric_exporter.reset
        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(10)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(10)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)
      end
    end
  end

  describe 'creating an instrument' do
    INSTRUMENT_NAME_ERROR = OpenTelemetry::Metrics::Meter::InstrumentNameError
    DUPLICATE_INSTRUMENT_ERROR = OpenTelemetry::Metrics::Meter::DuplicateInstrumentError

    it 'instrument name must not be nil' do
      _(-> { meter.create_counter(nil) }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instument name must not be an empty string' do
      _(-> { meter.create_counter('') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must have an alphabetic first character' do
      _(meter.create_counter('one_counter'))
      _(-> { meter.create_counter('1_counter') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must not exceed 255 character limit' do
      long_name = 'a' * 255
      meter.create_counter(long_name)
      _(-> { meter.create_counter(long_name + 'a') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must belong to alphanumeric characters, _, ., -, and /' do
      meter.create_counter('a_/-..-/_a')
      _(-> { meter.create_counter('a@') }).must_raise(INSTRUMENT_NAME_ERROR)
      _(-> { meter.create_counter('a!') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'allows any instrument unit' do
      counter = meter.create_counter('a_counter', unit: 'á')

      _(counter.instance_variable_get(:@unit)).must_equal('á')
    end

    it 'allows any instrument description' do
      description = 'a' * 1024
      counter = meter.create_counter('a_counter', description: description)

      _(counter.instance_variable_get(:@description)).must_equal(description)
    end

    it 'coerces nil unit and description to empty strings' do
      counter = meter.create_counter('a_counter')

      _(counter.instance_variable_get(:@unit)).must_equal('')
      _(counter.instance_variable_get(:@description)).must_equal('')
    end
  end

  describe 'duplicate instrument registration' do
    let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new }
    let(:meter) { meter_provider.meter('duplicate_registration') }

    it 'returns the same instrument for identical registrations' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        instrument = meter.create_counter('a_counter', unit: 'smidgen', description: 'a description')

        _(meter.create_counter('a_counter', unit: 'smidgen', description: 'a description')).must_be_same_as(instrument)
        _(log_stream.string).must_be_empty
      end
    end

    it 'warns and ignores callbacks on identical observable instrument registrations' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        callback_first = proc { 10 }
        callback_second = proc { 20 }
        instrument = meter.create_observable_counter('a_counter', callback: callback_first)

        _(meter.create_observable_counter('a_counter', callback: callback_second)).must_be_same_as(instrument)
        _(instrument.instance_variable_get(:@callbacks)).must_equal([callback_first])
        _(log_stream.string).must_match(/repeated observable instrument creation with callbacks for instrument name 'a_counter'. Ignoring new callbacks./)
      end
    end

    it 'does not warn about callbacks on identical observable instrument registrations with an empty callback array' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_counter('a_counter', callback: proc { 10 })
        meter.create_observable_counter('a_counter', callback: [])

        _(log_stream.string).wont_match(/Ignoring new callbacks/)
      end
    end

    it 'does not warn about callbacks on identical synchronous instrument registrations' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter')
        meter.create_counter('a_counter')

        _(log_stream.string).wont_match(/Ignoring new callbacks/)
      end
    end

    it 'keeps the callback of a conflicting observable instrument registration' do
      callback_first = proc { 10 }
      callback_second = proc { 20 }
      first = meter.create_observable_counter('a_counter', unit: 'smidgen', callback: callback_first)
      second = meter.create_observable_counter('a_counter', unit: 'flurbo', callback: callback_second)

      _(first.instance_variable_get(:@callbacks)).must_equal([callback_first])
      _(second.instance_variable_get(:@callbacks)).must_equal([callback_second])
    end

    it 'returns a functional instrument when identifying fields conflict' do
      first = meter.create_counter('a_counter', unit: 'smidgen')
      second = meter.create_counter('a_counter', unit: 'flurbo')

      _(second).must_be_instance_of(OpenTelemetry::SDK::Metrics::Instrument::Counter)
      _(second).wont_be_same_as(first)
    end

    it 'exports every conflicting instrument to a metric reader added later' do
      first = meter.create_counter('a_counter', unit: 'smidgen')
      second = meter.create_counter('a_counter', unit: 'flurbo')

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      meter_provider.add_metric_reader(metric_exporter)

      first.add(1)
      second.add(2)
      metric_exporter.pull
      snapshots = metric_exporter.metric_snapshots

      _(snapshots.map { |s| [s.name, s.unit, s.data_points.first.value] }).must_equal([%w[a_counter smidgen] + [1], %w[a_counter flurbo] + [2]])
    end

    it 'registers an identical instrument with a metric reader added later only once' do
      instrument = meter.create_counter('a_counter')
      meter.create_counter('A_COUNTER')

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      meter_provider.add_metric_reader(metric_exporter)

      instrument.add(1)
      metric_exporter.pull

      _(metric_exporter.metric_snapshots.size).must_equal(1)
    end

    it 'reports a description conflict' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter', description: 'first')
        meter.create_counter('a_counter', description: 'second')

        _(log_stream.string).must_match(/conflicting fields: description \("first" and "second"\)/)
      end
    end

    it 'reports a kind conflict' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter')
        meter.create_histogram('a_counter')

        _(log_stream.string).must_match(/conflicting fields: kind \(counter and histogram\)/)
      end
    end

    it 'returns the first-seen instrument name when only the casing differs' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        instrument = meter.create_counter('requestCount')

        _(meter.create_counter('RequestCount')).must_be_same_as(instrument)
        _(log_stream.string).must_match(/case-insensitive duplicate instrument registration occurred:'RequestCount' first seen as 'requestCount'/)
      end
    end

    it 'resolves the first-seen name and registers in a single critical section' do
      # Run a competing registration on another thread as soon as the first critical
      # section is released, so any gap between name resolution and registration is exposed.
      test_meter = meter
      competing = nil
      interleaved = false
      test_meter.instance_variable_get(:@mutex).define_singleton_method(:synchronize) do |&block|
        result = super(&block)
        unless interleaved
          interleaved = true
          Thread.new { competing = test_meter.create_counter('RequestCount') }.join
        end
        result
      end

      first = test_meter.create_counter('requestCount')

      _(competing).must_be_same_as(first)
      _(first.instance_variable_get(:@name)).must_equal('requestCount')
      _(test_meter.instance_variable_get(:@instrument_descriptors)['requestcount'].map(&:instrument)).must_equal([first])
    end

    it 'reports conflicting fields against the first-seen instrument name casing' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('requestCount')
        meter.create_histogram('RequestCount')

        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument name 'requestCount'/)
        _(log_stream.string).must_match(/conflicting fields: kind \(counter and histogram\)/)
      end
    end

    it 'reports every conflicting field' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter', unit: 'smidgen', description: 'first')
        meter.create_histogram('a_counter', unit: 'flurbo', description: 'second')

        _(log_stream.string).must_match(
          /conflicting fields: kind \(counter and histogram\), unit \("smidgen" and "flurbo"\), description \("first" and "second"\)/
        )
      end
    end
  end
end

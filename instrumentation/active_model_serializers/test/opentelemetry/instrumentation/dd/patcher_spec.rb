require 'ddtrace/contrib/support/spec_helper'
require 'ddtrace/contrib/analytics_examples'
require 'spec/ddtrace/contrib/active_model_serializers/helpers'

require 'active_support/all'
require 'active_model_serializers'
require 'ddtrace'
require 'ddtrace/contrib/active_model_serializers/patcher'
require 'ddtrace/ext/http'

RSpec.describe 'ActiveModelSerializers patcher' do
  include_context 'AMS serializer'

  let(:configuration_options) { {} }

  before(:each) do
    # Supress active_model_serializers log output in the test run
    ActiveModelSerializersHelpers.disable_logging

    Datadog.configure do |c|
      c.use :active_model_serializers, configuration_options
    end

    # Make sure to update the subscription tracer,
    # so we aren't writing to a stale tracer.
    if Datadog::Contrib::ActiveModelSerializers::Patcher.patched?
      Datadog::Contrib::ActiveModelSerializers::Events.subscriptions.each do |subscription|
        allow(subscription).to receive(:tracer).and_return(tracer)
      end
    end
  end

  around do |example|
    # Reset before and after each example; don't allow global state to linger.
    Datadog.registry[:active_model_serializers].reset_configuration!
    example.run
    Datadog.registry[:active_model_serializers].reset_configuration!
  end

  describe 'on render' do
    let(:test_obj) { TestModel.new(name: 'test object') }
    let(:serializer) { 'TestModelSerializer' }
    let(:adapter) { 'ActiveModelSerializers::Adapter::Attributes' }
    let(:event) { Datadog::Contrib::ActiveModelSerializers::Patcher.send(:event_name) }
    let(:name) do
      if ActiveModelSerializersHelpers.ams_0_10_or_newer?
        Datadog::Contrib::ActiveModelSerializers::Events::Render.span_name
      else
        Datadog::Contrib::ActiveModelSerializers::Events::Serialize.span_name
      end
    end

    let(:active_model_serializers_span) do
      spans.select { |s| s.name == name }.first
    end

    if ActiveModelSerializersHelpers.ams_0_10_or_newer?
      context 'when adapter is set' do
        subject(:render) { ActiveModelSerializers::SerializableResource.new(test_obj).serializable_hash }

        it_behaves_like 'analytics for integration' do
          let(:analytics_enabled_var) { Datadog::Contrib::ActiveModelSerializers::Ext::ENV_ANALYTICS_ENABLED }
          let(:analytics_sample_rate_var) { Datadog::Contrib::ActiveModelSerializers::Ext::ENV_ANALYTICS_SAMPLE_RATE }

          let(:span) do
            render
            active_model_serializers_span
          end
        end

        it_behaves_like 'measured span for integration', true do
          let(:span) do
            render
            active_model_serializers_span
          end
        end

        it 'is expected to send a span' do
          render

          active_model_serializers_span.tap do |span|
            expect(span).to_not be_nil
            expect(span.name).to eq(name)
            expect(span.resource).to eq(serializer)
            expect(span.service).to eq('active_model_serializers')
            expect(span.span_type).to eq(Datadog::Ext::HTTP::TEMPLATE)
            expect(span.get_tag('active_model_serializers.serializer')).to eq(serializer)
            expect(span.get_tag('active_model_serializers.adapter')).to eq(adapter)
          end
        end
      end
    end

    context 'when adapter is nil' do
      if ActiveModelSerializersHelpers.ams_0_10_or_newer?
        subject(:render) { ActiveModelSerializers::SerializableResource.new(test_obj, adapter: nil).serializable_hash }

        it 'is expected to send a span with adapter tag equal to the model name' do
          render

          active_model_serializers_span.tap do |span|
            expect(span).to_not be_nil
            expect(span.name).to eq(name)
            expect(span.resource).to eq(serializer)
            expect(span.service).to eq('active_model_serializers')
            expect(span.span_type).to eq(Datadog::Ext::HTTP::TEMPLATE)
            expect(span.get_tag('active_model_serializers.serializer')).to eq(serializer)
            expect(span.get_tag('active_model_serializers.adapter')).to eq(test_obj.class.to_s)
          end
        end
      else
        subject(:render) { TestModelSerializer.new(test_obj).as_json }

        it 'is expected to send a span with no adapter tag' do
          render

          active_model_serializers_span.tap do |span|
            expect(span).to_not be_nil
            expect(span.name).to eq(name)
            expect(span.resource).to eq(serializer)
            expect(span.service).to eq('active_model_serializers')
            expect(span.span_type).to eq(Datadog::Ext::HTTP::TEMPLATE)
            expect(span.get_tag('active_model_serializers.serializer')).to eq(serializer)
            expect(span.get_tag('active_model_serializers.adapter')).to be_nil
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

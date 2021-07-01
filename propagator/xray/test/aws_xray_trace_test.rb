# frozen_string_literal: true

require 'date'
require 'test_helper'

describe OpenTelemetry::Trace::SpanContext do
  let(:id_generator) { OpenTelemetry::Propagator::XRay::IDGenerator }

  describe 'generate trace id in the correct format' do
    it 'must generate 16 in length' do
      trace_id = id_generator.generate_trace_id
      _(trace_id.length).must_equal(16)
    end
    it 'first 4 bytes should be a valid epoch date' do
      trace_id = id_generator.generate_trace_id
      # Convert to hex
      hex = trace_id[0..3].unpack1('H*')
      # Convert to int
      time_int = hex.to_i(16)
      # Convert to datetime
      begin
        date = Time.at(time_int).to_datetime
      rescue ArgumentError
        date = nil
      end
      # Make sure it's valid
      _(date).wont_be_nil
    end
    it 'generate_span_id still works' do
      trace_id = id_generator.generate_span_id
      # Make sure it's valid
      _(trace_id).wont_be_nil
    end
  end
end

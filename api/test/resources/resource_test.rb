# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Resources::Resource do
  describe '#labels' do
    it 'returns a hash of labels' do
      resource = OpenTelemetry::Resources::Resource.new(k1: 'v1', k2: 'v2')
      expected_labels = { 'k1' => 'v1', 'k2' => 'v2' }
      resource.labels.must_equal(expected_labels)
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Resources::Resource do
  describe '#labels' do
    it 'returns a hash of labels' do
      expected_labels = { 'k1' => 'v1', 'k2' => 'v2' }
      resource = OpenTelemetry::Resources::Resource.new(expected_labels)
      resource.labels.must_equal(expected_labels)
    end
  end

  describe '#merge' do
    it 'merges two resources into a third' do
      res1 = OpenTelemetry::Resources::Resource.new('k1' => 'v1', 'k2' => 'v2')
      res2 = OpenTelemetry::Resources::Resource.new('k3' => 'v3', 'k4' => 'v4')
      res3 = res1.merge(res2)

      res3.labels.must_equal('k1' => 'v1', 'k2' => 'v2',
                             'k3' => 'v3', 'k4' => 'v4')
      res1.labels.must_equal('k1' => 'v1', 'k2' => 'v2')
      res2.labels.must_equal('k3' => 'v3', 'k4' => 'v4')
    end
  end
end

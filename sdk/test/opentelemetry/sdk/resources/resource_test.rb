# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Resources::Resource do
  Resource = OpenTelemetry::SDK::Resources::Resource

  describe '.new' do
    it 'is private' do
      _(proc { Resource.new('k1' => 'v1') }).must_raise(NoMethodError)
    end
  end

  describe '.create' do
    it 'can be initialized with labels' do
      expected_labels = { 'k1' => 'v1', 'k2' => 'v2' }
      resource = Resource.create(expected_labels)
      _(resource.label_enumerator.to_h).must_equal(expected_labels)
    end

    it 'can be empty' do
      resource = Resource.create
      _(resource.label_enumerator.to_h).must_be_empty
    end

    it 'enforces keys are strings' do
      _(proc { Resource.create(k1: 'v1') }).must_raise(ArgumentError)
    end

    it 'enforces values are strings' do
      _(proc { Resource.create('k1' => :v1) }).must_raise(ArgumentError)
    end
  end

  describe '#merge' do
    it 'merges two resources into a third' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create('k3' => 'v3', 'k4' => 'v4')
      res3 = res1.merge(res2)

      _(res3.label_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2',
                                               'k3' => 'v3', 'k4' => 'v4')
      _(res1.label_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2')
      _(res2.label_enumerator.to_h).must_equal('k3' => 'v3', 'k4' => 'v4')
    end

    it 'does not overwrite receiver\'s keys when value is non-empty' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create('k2' => '2v2', 'k3' => '2v3')
      res3 = res1.merge(res2)

      _(res3.label_enumerator.to_h).must_equal('k1' => 'v1',
                                               'k2' => 'v2',
                                               'k3' => '2v3')
    end

    it 'overwrites receiver\'s key when value is empty' do
      res1 = Resource.create('k1' => 'v1', 'k2' => '')
      res2 = Resource.create('k2' => '2v2', 'k3' => '2v3')
      res3 = res1.merge(res2)

      _(res3.label_enumerator.to_h).must_equal('k1' => 'v1',
                                               'k2' => '2v2',
                                               'k3' => '2v3')
    end
  end
end

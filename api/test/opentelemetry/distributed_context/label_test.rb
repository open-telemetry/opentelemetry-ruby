# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::DistributedContext::Label do
  Label = OpenTelemetry::DistributedContext::Label
  Metadata = OpenTelemetry::DistributedContext::Label::Metadata

  describe '.new' do
    let(:label) do
      Label.new(
        key: 'k',
        value: 'v',
        metadata: Metadata.new(Metadata::UNLIMITED_PROPAGATION)
      )
    end

    it 'returns new label' do
      _(label.key).must_equal('k')
      _(label.value).must_equal('v')
      _(label.metadata.hop_limit).must_equal(Metadata::UNLIMITED_PROPAGATION)
    end

    it 'freezes key and value' do
      _(label.key).must_be(:frozen?)
      _(label.value).must_be(:frozen?)
    end
  end
end

# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::DistributedContext::Label do
  Label = OpenTelemetry::DistributedContext::Label
  Key = OpenTelemetry::DistributedContext::Label::Key
  Value = OpenTelemetry::DistributedContext::Label::Value
  Metadata = OpenTelemetry::DistributedContext::Label::Metadata

  describe '.new' do
    it 'returns new label' do
      label = Label.new(
        key: Key.new('k'),
        value: Value.new('v'),
        metadata: Metadata.new(Metadata::UNLIMITED_PROPAGATION)
      )
      _(label.key.name).must_equal('k')
      _(label.value.to_s).must_equal('v')
      _(label.metadata.hop_limit).must_equal(Metadata::UNLIMITED_PROPAGATION)
    end
  end
end

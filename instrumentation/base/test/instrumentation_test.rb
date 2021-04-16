# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation do
  describe '.registry' do
    it 'returns an instance of Instrumentation::Registry' do
      _(OpenTelemetry::Instrumentation.registry).must_be_instance_of(
        OpenTelemetry::Instrumentation::Registry
      )
    end
  end
end

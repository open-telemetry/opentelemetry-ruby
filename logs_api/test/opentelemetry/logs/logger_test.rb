# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Logs::Logger do
  let(:logger) { OpenTelemetry::Logs::Logger.new }

  describe '#on_emit' do
    it 'returns nil, as it is a no-op method' do
      assert_nil(logger.on_emit)
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Logs::LoggerProvider do
  let(:logger_provider) { OpenTelemetry::Logs::LoggerProvider.new }
  let(:args) { { name: 'component', version: '1.0' } }
  let(:args2) { { name: 'component2', version: '1.0' } }

  describe '#logger' do
    it 'returns the same no-op logger' do
      assert_same(
        logger_provider.logger(**args),
        logger_provider.logger(**args2)
      )
    end
  end
end

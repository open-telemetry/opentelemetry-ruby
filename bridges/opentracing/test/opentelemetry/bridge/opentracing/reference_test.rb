# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Reference do
  Reference = OpenTelemetry::Bridge::OpenTracing::Reference
  let(:mock_link) { Minitest::Mock.new }
  describe '#context' do
    it 'sets the context' do
      mock_link.expect(:context, 'context')
      reference = Reference.new(mock_link)
      reference.context.must_equal 'context'
      mock_link.verify
    end

    it 'sets the type' do
      mock_link.expect(:context, nil)
      reference = Reference.new(mock_link, type: 'type')
      reference.type.must_equal 'type'
      mock_link.verify
    end
  end
end

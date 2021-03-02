# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/google_apis_core'

describe OpenTelemetry::Instrumentation::GoogleApisCore do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GoogleApisCore::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::GoogleApisCore'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      instrumentation.install({})
    end
  end
end

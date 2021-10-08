# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/rspec'

describe OpenTelemetry::Instrumentation::RSpec do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RSpec::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::RSpec'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end

    it 'adds the formatter to RSpec configuration' do
      _(instrumentation.install({})).must_equal(true)
      _(RSpec.configuration.formatters.map(&:class)).must_include OpenTelemetry::Instrumentation::RSpec::Formatter
    end
  end
end

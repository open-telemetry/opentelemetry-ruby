# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/sinatra/adapter'

describe OpenTelemetry::Adapters::Sinatra::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Sinatra::Adapter }
  let(:instance) { adapter.new }

  before do
    adapter.install
  end

  describe '#install' do
    it 'installs once' do
      instance.install

      _(instance.install).must_equal(:registered_already)
    end
  end
end

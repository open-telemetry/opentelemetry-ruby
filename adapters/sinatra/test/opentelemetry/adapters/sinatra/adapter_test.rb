# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/sinatra/adapter'

describe OpenTelemetry::Adapters::Sinatra::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Sinatra::Adapter }
  let(:instance) { adapter.new }

  describe '#install' do
    it 'installs once' do
      # installation is only allowed once globally, so this test works
      # in isolation, but not when run in a suite:
      # _(instance.install).must_equal(:installed)

      instance.install

      _(instance.install).must_equal(:already_installed)
    end
  end
end

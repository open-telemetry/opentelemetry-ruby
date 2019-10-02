# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::MultiSpanProcessor do
  let(:mock_processor1)    { Minitest::Mock.new }
  let(:mock_processor2)    { Minitest::Mock.new }
  let(:span)               { 'dummy span' }

  let(:processor) do
    OpenTelemetry::SDK::Trace::MultiSpanProcessor.new(
      [mock_processor1, mock_processor2]
    )
  end

  it 'implements #on_start' do
    mock_processor1.expect :on_start, nil, [span]
    mock_processor2.expect :on_start, nil, [span]

    processor.on_start(span)

    mock_processor1.verify
    mock_processor2.verify
  end

  it 'implements #on_finish' do
    mock_processor1.expect :on_finish, nil, [span]
    mock_processor2.expect :on_finish, nil, [span]

    processor.on_finish(span)

    mock_processor1.verify
    mock_processor2.verify
  end

  it 'implements #shutdown' do
    mock_processor1.expect :shutdown, nil
    mock_processor2.expect :shutdown, nil

    processor.shutdown

    mock_processor1.verify
    mock_processor2.verify
  end
end

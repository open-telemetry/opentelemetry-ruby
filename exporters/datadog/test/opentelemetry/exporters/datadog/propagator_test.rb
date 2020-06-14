# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

describe OpenTelemetry::Exporters::Datadog::Exporter do
  describe '#inject' do
    it 'yields the carrier' do
    end

    it 'injects the datadog appropriate trace information into the carrier from the context, if provided' do
    end
  end

  describe '#extract' do
    it 'returns original context on error' do
    end

    it 'returns a remote SpanContext with fields from the datadog headers' do
    end

    it 'accounts for rack specific headers' do
    end
  end
end

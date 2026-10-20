# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# Builders must supply every keyword unless its SDK default is known to be
# environment-free. A new constructor keyword must be reviewed explicitly.
describe 'declarative config constructor keywords' do
  KEYWORD_TYPES = %i[key keyreq].freeze

  ENV_FREE_KEYWORDS = {
    OpenTelemetry::SDK::Trace::TracerProvider => %i[id_generator],
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor => %i[metrics_reporter],
    OpenTelemetry::Exporter::OTLP::Exporter => %i[metrics_reporter]
  }.freeze

  YAML_CONFIG = <<~YAML
    file_format: "1.0"
    tracer_provider:
      processors:
        - batch:
            exporter:
              otlp_http: {}
  YAML

  # Returns the keyword parameter names of +klass#initialize+.
  def keyword_params(klass)
    klass.instance_method(:initialize).parameters.filter_map { |type, name| name if KEYWORD_TYPES.include?(type) }
  end

  # Records the keywords passed to +klass.new+ through the public config path.
  def captured_keywords(klass)
    captured = nil
    original = klass.method(:new)
    recorder = lambda do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block).tap { captured = kwargs.keys }
    end

    klass.stub(:new, recorder) do
      with_config(YAML_CONFIG) { |path| OpenTelemetry::Config.configure_from_file(path) }
    end
    captured
  end

  [
    OpenTelemetry::SDK::Trace::TracerProvider,
    OpenTelemetry::SDK::Trace::SpanLimits,
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor,
    OpenTelemetry::Exporter::OTLP::Exporter
  ].each do |klass|
    it "passes every environment-backed keyword to #{klass}" do
      expected = keyword_params(klass) - ENV_FREE_KEYWORDS.fetch(klass, [])
      passed = captured_keywords(klass)

      _(passed).wont_be_nil "#{klass}.new was not called; an SDK default object may be in use"
      _(expected - passed).must_be_empty "keywords left to environment defaults: #{expected - passed}"
    end
  end
end

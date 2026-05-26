# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/otelconfig/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-otelconfig'
  spec.version     = OpenTelemetry::OtelConfig::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Declare Config implementation for OpenTelemetry'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.3'

  spec.add_development_dependency 'opentelemetry-api', '~> 1.10.0'
  spec.add_development_dependency 'opentelemetry-common', '~> 0.25.0'
  spec.add_development_dependency 'opentelemetry-exporter-otlp', '~> 0.34.0'
  spec.add_development_dependency 'opentelemetry-instrumentation-all', '~> 0.91.0'
  spec.add_development_dependency 'opentelemetry-propagator-google_cloud_trace_context', '~> 0.4.0'
  spec.add_development_dependency 'opentelemetry-propagator-ottrace', '~> 0.25.0'
  spec.add_development_dependency 'opentelemetry-propagator-xray', '~> 0.27.0'
  spec.add_development_dependency 'opentelemetry-resource-detector-aws', '~> 0.5.0'
  spec.add_development_dependency 'opentelemetry-resource-detector-azure', '~> 0.3.0'
  spec.add_development_dependency 'opentelemetry-resource-detector-container', '~> 0.3.0'
  spec.add_development_dependency 'opentelemetry-resource-detector-google_cloud_platform', '~> 0.4.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.12'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-logs-sdk/v#{OpenTelemetry::OtelConfig::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = "https://github.com/open-telemetry/opentelemetry-ruby/tree/#{spec.name}/v#{spec.version}/logs_sdk"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] =
      "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-logs-sdk/v#{OpenTelemetry::OtelConfig::VERSION}"
  end
end

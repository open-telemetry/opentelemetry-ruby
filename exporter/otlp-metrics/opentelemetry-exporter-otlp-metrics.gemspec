# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/exporter/otlp/metrics/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-exporter-otlp-metrics'
  spec.version     = OpenTelemetry::Exporter::OTLP::Metrics::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'OTLP metrics exporter for the OpenTelemetry framework'
  spec.description = 'OTLP metrics exporter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'googleapis-common-protos-types', '~> 1.3'
  spec.add_dependency 'google-protobuf', '>= 3.18', '< 5.0'
  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.20'
  spec.add_dependency 'opentelemetry-metrics-api', '~> 0.2'
  spec.add_dependency 'opentelemetry-metrics-sdk', '~> 0.5'
  spec.add_dependency 'opentelemetry-sdk', '~> 1.2'
  spec.add_dependency 'opentelemetry-semantic_conventions'

  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-otlp-metrics/v#{OpenTelemetry::Exporter::OTLP::Metrics::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = "https://github.com/open-telemetry/opentelemetry-ruby/tree/#{spec.name}/v#{spec.version}/exporter/otlp-metrics"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-otlp-metrics/v#{OpenTelemetry::Exporter::OTLP::Metrics::VERSION}"
  end
end

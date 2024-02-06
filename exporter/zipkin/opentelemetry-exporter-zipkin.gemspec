# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/exporter/zipkin/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-exporter-zipkin'
  spec.version     = OpenTelemetry::Exporter::Zipkin::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Zipkin trace exporter for the OpenTelemetry framework'
  spec.description = 'Zipkin trace exporter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('thrift/gen-rb/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'csv', '~> 3.1'
  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.20'
  spec.add_dependency 'opentelemetry-sdk', '~> 1.2'
  spec.add_dependency 'opentelemetry-semantic_conventions'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'faraday', '~> 0.13'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 1.51.0'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'webmock', '~> 3.7.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-zipkin/v#{OpenTelemetry::Exporter::Zipkin::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/exporter/zipkin'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-zipkin/v#{OpenTelemetry::Exporter::Zipkin::VERSION}"
  end
end

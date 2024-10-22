# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/exporter/otlp/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-exporter-otlp-logs'
  spec.version     = OpenTelemetry::Exporter::OTLP::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Experimental OTLP Logs exporter for the OpenTelemetry framework'
  spec.description = 'Experimental OTLP Logs exporter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'googleapis-common-protos-types', '~> 1.3'
  spec.add_dependency 'google-protobuf', '>= 3.18'
  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.20'
  spec.add_dependency 'opentelemetry-logs-api', '~> 0.1'
  spec.add_dependency 'opentelemetry-logs-sdk', '~> 0.1'
  spec.add_dependency 'opentelemetry-sdk'
  spec.add_dependency 'opentelemetry-semantic_conventions'

  spec.add_development_dependency 'appraisal', '~> 2.2.0'
  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'faraday', '~> 0.13'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 1.3'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'webmock', '~> 3.7.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-otlp/v#{OpenTelemetry::Exporter::OTLP::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/exporter/otlp'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-exporter-otlp/v#{OpenTelemetry::Exporter::OTLP::VERSION}"
  end
end

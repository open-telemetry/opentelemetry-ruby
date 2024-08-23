# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/sdk/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-sdk'
  spec.version     = OpenTelemetry::SDK::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'A stats collection and distributed tracing framework'
  spec.description = 'A stats collection and distributed tracing framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.20'
  spec.add_dependency 'opentelemetry-registry', '~> 0.2'

  # This is an intentionally loose dependency, since we want to be able to
  # release new versions of opentelemetry-semantic_conventions without requiring
  # a new SDK release. The requirements of the SDK have been satisfied since the
  # initial release of opentelemetry-semantic_conventions, so we feel it is safe.
  spec.add_dependency 'opentelemetry-semantic_conventions'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'faraday', '~> 0.13'
  spec.add_development_dependency 'minitest', '~> 5.15.0'
  spec.add_development_dependency 'opentelemetry-exporter-zipkin', '~> 0.19.0'
  spec.add_development_dependency 'opentelemetry-instrumentation-base', '~> 0.20'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 1.65'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-sdk/v#{OpenTelemetry::SDK::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/sdk'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-sdk/v#{OpenTelemetry::SDK::VERSION}"
  end
end

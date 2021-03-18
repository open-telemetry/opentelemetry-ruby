# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'opentelemetry/instrumentation/all/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-all'
  spec.version     = OpenTelemetry::Instrumentation::All::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'All-in-one instrumentation bundle for the OpenTelemetry framework'
  spec.description = 'All-in-one instrumentation bundle for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'opentelemetry-instrumentation-active_model_serializers', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-concurrent_ruby', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-dalli', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-delayed_job', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-ethon', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-excon', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-faraday', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-graphql', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-http', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-http_client', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-lmdb', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-mongo', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-mysql2', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-net_http', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-rack', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-rails', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-redis', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-restclient', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-ruby_kafka', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-sidekiq', '~> 0.16.0'
  spec.add_dependency 'opentelemetry-instrumentation-sinatra', '~> 0.16.0'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.73.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-all/v#{OpenTelemetry::Instrumentation::All::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation/all'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-all/v#{OpenTelemetry::Instrumentation::All::VERSION}"
  end
end

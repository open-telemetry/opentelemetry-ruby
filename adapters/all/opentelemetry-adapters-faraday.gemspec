# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'opentelemetry/adapters/all/version'
version = OpenTelemetry::Adapters::All::VERSION

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-adapters-all'
  spec.version     = OpenTelemetry::Adapters::All::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'All-in-one instrumentation adapter bundle for the OpenTelemetry framework'
  spec.description = 'All-in-one instrumentation adapter bundle for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency 'opentelemetry-adapters-concurrent_ruby', version
  spec.add_dependency 'opentelemetry-adapters-ethon', version
  spec.add_dependency 'opentelemetry-adapters-excon', version
  spec.add_dependency 'opentelemetry-adapters-faraday', version
  spec.add_dependency 'opentelemetry-adapters-net_http', version
  spec.add_dependency 'opentelemetry-adapters-rack', version
  spec.add_dependency 'opentelemetry-adapters-redis', version
  spec.add_dependency 'opentelemetry-adapters-restclient', version
  spec.add_dependency 'opentelemetry-adapters-sinatra', version

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.73.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'
end

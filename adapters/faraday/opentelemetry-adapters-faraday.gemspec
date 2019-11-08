# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/adapters/faraday/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-adapters-faraday'
  spec.version     = OpenTelemetry::Adapters::Faraday::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Faraday instrumentation adapter for the OpenTelemetry framework'
  spec.description = 'Faraday instrumentation adapter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency 'opentelemetry-api', '~> 0.0'
  spec.add_dependency 'faraday', '~> 0.17.0'

  spec.add_development_dependency 'bundler', '>= 1.17'
end

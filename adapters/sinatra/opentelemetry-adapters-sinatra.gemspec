# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/adapters/sinatra/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-adapters-sinatra'
  spec.version     = OpenTelemetry::Adapters::Sinatra::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Sinatra instrumentation adapter for the OpenTelemetry framework'
  spec.description = 'Sinatra instrumentation adapter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency 'opentelemetry-api', '~> 0.0'
  spec.add_dependency 'sinatra', '~> 2.0.7'

  spec.add_development_dependency 'bundler', '>= 1.17'
end

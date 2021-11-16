# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/rails/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-rails'
  spec.version     = OpenTelemetry::Instrumentation::Rails::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Rails instrumentation for the OpenTelemetry framework'
  spec.description = 'Rails instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'
  spec.add_dependency 'opentelemetry-instrumentation-action_pack', '~> 0.1.2'
  spec.add_dependency 'opentelemetry-instrumentation-action_view', '~> 0.1.3'
  spec.add_dependency 'opentelemetry-instrumentation-active_record', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-instrumentation-active_support', '~> 0.1.0'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.18.3'

  spec.add_development_dependency 'appraisal', '~> 2.2.0'
  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.0'
  spec.add_development_dependency 'rack-test', '~> 1.1.0'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rubocop', '~> 0.73.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'webmock', '~> 3.7.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation/rails' if spec.respond_to?(:metadata)
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/active_support/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-active_support'
  spec.version     = OpenTelemetry::Instrumentation::ActiveSupport::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'ActiveSupport instrumentation for the OpenTelemetry framework'
  spec.description = 'ActiveSupport instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.18.3'

  spec.add_development_dependency 'appraisal', '~> 2.2.0'
  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rubocop', '~> 0.73.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'webmock', '~> 3.7.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-active_support/v#{OpenTelemetry::Instrumentation::ActiveSupport::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation/active_support'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-active_support/v#{OpenTelemetry::Instrumentation::ActiveSupport::VERSION}"
  end
end

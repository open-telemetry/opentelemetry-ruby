# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'lib/opentelemetry/propagator/ottrace/version'

Gem::Specification.new do |spec|
  spec.name          = 'opentelemetry-propagator-ottrace'
  spec.version       = OpenTelemetry::Propagator::OTTrace::VERSION
  spec.authors       = ['OpenTelemetry Authors']
  spec.email         = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'OTTrace Context Propagation Extension for the OpenTelemetry framework'
  spec.description = 'OTTrace Context Propagation Extension for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'opentelemetry-api', "~> #{OpenTelemetry::Propagator::OTTrace::VERSION}"

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', "~> #{OpenTelemetry::Propagator::OTTrace::VERSION}"
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.73.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-propagator-ottrace/v#{OpenTelemetry::Propagator::OTTrace::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/propagator/ottrace'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-propagator-ottrace/v#{OpenTelemetry::Propagator::OTTrace::VERSION}"
  end
end

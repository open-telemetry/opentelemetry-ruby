# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/sdk/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry_sdk_rust'
  spec.version     = OpenTelemetry::SDK::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'A stats collection and distributed tracing framework'
  spec.description = 'A stats collection and distributed tracing framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6.0'
  spec.extensions = ['ext/opentelemetry_sdk_rust/extconf.rb']

  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.19.3'

  # needed until rubygems supports Rust support is out of beta
  spec.add_dependency 'rb_sys', '~> 0.9.44'

  # actually a build time dependency, but that's not an option.
  spec.add_runtime_dependency 'rake', '~> 12.0'

  # only needed when developing or packaging your gem
  spec.add_development_dependency 'rake-compiler', '~> 1.2.0'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'minitest', '~> 5.15.0'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.0'

  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-sdk/v#{OpenTelemetry::SDK::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/tree/main/sdk'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-sdk/v#{OpenTelemetry::SDK::VERSION}"
  end
end

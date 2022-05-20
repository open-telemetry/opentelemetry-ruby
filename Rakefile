# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

namespace :each do
  task :bundle_install do
    foreach_gem { do_cmd('bundle install') }
  end

  task :bundle_update do
    foreach_gem { do_cmd('bundle update') }
  end

  task :test do
    foreach_gem { do_cmd('bundle exec rake test') }
  end

  task :yard do
    foreach_gem { do_cmd('bundle exec rake yard') }
  end

  task :rubocop do
    foreach_gem { do_cmd('bundle exec rake rubocop') }
  end

  task :default do
    foreach_gem { do_cmd('bundle exec rake') }
  end

  task :validate_otel_dependencies do
    gems = {}

    foreach_gem do |name|
      puts "***** Loading #{name}.gemspec"
      spec = Gem::Specification::load("#{name}.gemspec")
      gems[spec.name] = spec
    end

    gems.each do |gem_name, gem_spec|
      puts "**** Validating OpenTelemetry dependencies for #{gem_name}"
      gem_spec.dependencies.select { |s| s.name =~ /^opentelemetry/ }.each do |gem_dependency|
        print "***** Checking for #{gem_dependency}"
        other_gem_spec = gems[gem_dependency.name]

        if other_gem_spec.nil?
          puts ' ❌'
          puts "****** Didn't find a spec for #{gem_dependency.name} - is this a valid opentelemetry-ruby gem?"
          exit 1
        end

        if !gem_dependency.matches_spec?(other_gem_spec)
          puts ' ❌'
          puts "****** Dependency not satisfied!"
          exit 1
        end

        puts ' ✅'
      end
    end
  end
end

task each: 'each:default'

task default: [:each]

def do_cmd(cmd)
  if defined?(Bundler)
    Bundler.with_clean_env do
      sh(cmd)
    end
  else
    sh(cmd)
  end
end

def foreach_gem(&block)
  Dir.glob("**/opentelemetry-*.gemspec") do |gemspec|
    name = File.basename(gemspec, ".gemspec")
    dir = File.dirname(gemspec)
    puts "**** Entering #{dir}"
    Dir.chdir(dir) do
      yield name
    end
  end
end

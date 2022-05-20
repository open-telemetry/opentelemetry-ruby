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
    require 'gems'
    require 'pathname'

    gem_specs = {}
    rubygems_versions = {}

    changed_gems = `git diff --name-only FETCH_HEAD...main *.gemspec`.split("\n").map do |gemspec|
      Pathname.new(gemspec).basename.sub(/\.gemspec/, '')
    end

    foreach_gem do |name|
      puts "***** Getting info for #{name}"

      puts "****** Loading #{name}.gemspec"
      spec = Gem::Specification::load("#{name}.gemspec")
      gem_specs[spec.name] = spec

      puts "****** Getting latest released version of #{name} from rubygems.org"
      begin
        rubygems_versions[name] = Gems.info(name)
      rescue Gems::NotFound
        puts "******* #{name} not found on rubygems.org, trying to continue..."
      end
    end

    gem_specs.each do |gem_name, gem_spec|
      puts "**** Validating OpenTelemetry dependencies for #{gem_name}"
      gem_spec.dependencies.select { |s| s.name =~ /^opentelemetry/ }.each do |gem_dependency|
        print "***** Checking for #{gem_dependency}"

        # Are we releasing this dependency right now?
        if changed_gems.include?(gem_dependency.name)
          # If so, let's find the gemspec for the to-be-released version...
          other_gem_spec = gems[gem_dependency.name]
          if gem_dependency.matches_spec?(other_gem_spec)
            # Great, it matches, we're good. Provided the release succeeds...
            puts ' ✅'
          else
            # Whoops - we're not releasing a version that will satisfy the dependency.
            puts ' ❌'
            puts "****** Dependency not satisfied!"
            puts "****** #{gem_name} required #{gem_dependency}"
            puts "****** We are releasing #{gem_dependency.name} in this PR, but we will be releasing version #{other_gem_spec.version}!"
            exit 1
          end
        else
          # We are not releasing this dependency right now, so we should make sure that
          # the latest version on rubygems.org will satisfy the dependency.
          gem_info = rubygems_versions[gem_dependency.name]
          if gem_info.nil?
            puts ' ❌'
            puts "****** Dependency not satisfied!"
            puts "****** #{gem_name} required #{gem_dependency}"
            puts "****** We are not releasing #{gem_dependency.name}, and it isn't published to rubygems.org!"
            exit 1
          end

          other_gem_spec = Gem::Specification.new do |s|
            s.name = gem_info["name"]
            s.version = gem_info["version"]
          end

          if gem_dependency.matches_spec?(other_gem_spec)
            # Great, it matches, we're good. Provided the release succeeds...
            puts ' ✅'
          else
            # Whoops - we're not releasing a version that will satisfy the dependency.
            puts ' ❌'
            puts "****** Dependency not satisfied!"
            puts "****** #{gem_name} required #{gem_dependency}"
            puts "****** The latest version on rubygems.org is #{other_gem_spec.version}!"
            exit 1
          end
        end
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

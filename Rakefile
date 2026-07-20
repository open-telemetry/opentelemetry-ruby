# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

namespace :each do
  task :bundle_install do
    foreach_gem('bundle install')
  end

  task :bundle_update do
    foreach_gem('bundle update')
  end

  task :test do
    foreach_gem('bundle exec rake test')
  end

  task :yard do
    foreach_gem('bundle exec rake yard')
  end

  desc "Run rubocop in each gem"
  task :rubocop do
    foreach_gem('bundle exec rake rubocop')
  end

  task :default do
    foreach_gem('bundle exec rake')
  end
end

task each: 'each:default'

task default: [:each]

task :collate_simplecov, [:dir] do |t, args|
  if RUBY_ENGINE == 'truffleruby'
    exit 0
  end

  puts "dir is: '#{args[:dir]}'"
  require 'dotenv'
  Dotenv.load(File.expand_path(".env", "#{args[:dir]}/test"))

  require 'simplecov'
  SimpleCov.start
  SimpleCov.collate Dir["#{args[:dir]}/coverage/**/.resultset.json"]
end

def foreach_gem(cmd)
  Dir.glob("**/opentelemetry-*.gemspec") do |gemspec|
    name = File.basename(gemspec, ".gemspec")
    dir = File.dirname(gemspec)
    puts "**** Entering #{dir}"
    Dir.chdir(dir) do
      if defined?(Bundler)
        Bundler.with_clean_env do
          sh(cmd)
        end
      else
        sh(cmd)
      end
    end
  end
end

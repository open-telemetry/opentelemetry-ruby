# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
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

  task :rubocop do
    foreach_gem('bundle exec rake rubocop')
  end

  task :default do
    foreach_gem('bundle exec rake')
  end
end

task each: 'each:default'

task :push_release do
  push_release
end

task default: [:each]

GEM_INFO = {
  "opentelemetry-api" => {
    version_getter: ->() {
      require './lib/opentelemetry/version.rb'
      OpenTelemetry::VERSION
    }
  },
  "opentelemetry-sdk" => {
    version_getter: ->() {
      require './lib/opentelemetry/sdk/version.rb'
      OpenTelemetry::SDK::VERSION
    }
  },
  "opentelemetry-exporters-jaeger" => {
    version_getter: ->() {
      require './lib/opentelemetry/exporters/jaeger/version.rb'
      OpenTelemetry::Exporters::Jaeger::VERSION
    }
  },
  "opentelemetry-adapters-ethon" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/ethon/version.rb'
      OpenTelemetry::Adapters::Ethon::VERSION
    }
  },
  "opentelemetry-adapters-excon" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/excon/version.rb'
      OpenTelemetry::Adapters::Excon::VERSION
    }
  },
  "opentelemetry-adapters-concurrent_ruby" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/concurrent_ruby/version.rb'
      OpenTelemetry::Adapters::ConcurrentRuby::VERSION
    }
  },
  "opentelemetry-adapters-faraday" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/faraday/version.rb'
      OpenTelemetry::Adapters::Faraday::VERSION
    }
  },
  "opentelemetry-adapters-net_http" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/net/http/version.rb'
      OpenTelemetry::Adapters::Net::HTTP::VERSION
    }
  },
  "opentelemetry-adapters-rack" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/rack/version.rb'
      OpenTelemetry::Adapters::Rack::VERSION
    }
  },
  "opentelemetry-adapters-redis" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/redis/version.rb'
      OpenTelemetry::Adapters::Redis::VERSION
    }
  },
  "opentelemetry-adapters-restclient" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/restclient/version.rb'
      OpenTelemetry::Adapters::RestClient::VERSION
    }
  },
  "opentelemetry-adapters-sidekiq" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/sidekiq/version.rb'
      OpenTelemetry::Adapters::Sidekiq::VERSION
    }
  },
  "opentelemetry-adapters-sinatra" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/sinatra/version.rb'
      OpenTelemetry::Adapters::Sinatra::VERSION
    }
  },
  "opentelemetry-adapters-all" => {
    version_getter: ->() {
      require './lib/opentelemetry/adapters/all/version.rb'
      OpenTelemetry::Adapters::All::VERSION
    }
  }
}

def foreach_gem(cmd)
  GEM_INFO.keys.each do |name|
    dir = gem_dir(name)
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

def push_release
  name, version = parse_tag
  puts("Releasing #{name} version #{version}")
  Dir.chdir(gem_dir(name)) do
    using_api_key do
      sh("gem build #{name}.gemspec")
      if ENV['OPENTELEMETRY_RELEASES_ENABLED'] =~ /^t/i
        sh("gem push #{name}-#{version}.gem")
        puts("SUCCESS: Released #{name} #{version}")
      else
        sh("test -f #{name}-#{version}.gem")
        puts("SUCCESS: Mock release of #{name} #{version}")
      end
    end
  end
end

def parse_tag
  tag = ENV['CIRCLE_TAG']
  match = %r{^(opentelemetry-[\w-]+)/v(.*)$}.match(tag)
  abort_release("Unexpected tag: #{tag.inspect}") unless match
  name = match[1]
  version = match[2]
  gem_info = GEM_INFO[name]
  abort_release("Unknown gem: #{name}") unless gem_info
  lib_version = Dir.chdir(gem_dir(name)) do
    gem_info[:version_getter].call
  end
  unless version == lib_version
    abort_release("Tagged version #{version.inspect} doesn't match" \
                  " library version #{lib_version.inspect}")
  end
  [name, version]
end

def using_api_key
  api_key = ENV['OPENTELEMETRY_RUBYGEMS_API_KEY']
  creds_path = "#{ENV['HOME']}/.gem/credentials"
  creds_exist = File.exist?(creds_path)
  if creds_exist && !api_key
    puts('Using existing Rubygems credentials')
    yield
    return
  end
  abort_release('OPENTELEMETRY_RUBYGEMS_API_KEY not found') unless api_key
  abort_release("#{creds_path} already exists") if creds_exist
  begin
    mkdir_p("#{ENV['HOME']}/.gem")
    File.open(creds_path, 'w', 0o600) do |file|
      file.puts("---\n:rubygems_api_key: #{api_key}")
    end
    puts('Using OPENTELEMETRY_RUBYGEMS_API_KEY')
    yield
  ensure
    sh("shred -u #{creds_path}")
  end
end

def gem_dir(name)
  name.split('-')[1..-1].join('/')
end

def abort_release(message)
  abort("!!!! RELEASE FAILED !!!!\n#{message}")
end

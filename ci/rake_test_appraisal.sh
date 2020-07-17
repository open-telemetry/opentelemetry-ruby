#!/bin/bash

root=$(pwd)

printf "\nname: Bundle + CI (Instrumentation - Concurrent Ruby) \n"
cd instrumentation/concurrent_ruby
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - ethon) \n"
cd instrumentation/ethon
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - excon) \n"
cd instrumentation/excon
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

# name: Bundle + CI (Instrumentation - Faraday)
cd instrumentation/faraday
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - Net::HTTP) \n"
cd instrumentation/net_http
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - Rack) \n"
cd instrumentation/rack
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - Redis) \n"
cd instrumentation/redis
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - REST Client) \n"
cd instrumentation/restclient
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd ../..

printf "\nname: Bundle + CI (Instrumentation - Sidekiq) \n"
cd instrumentation/sidekiq
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

printf "\nname: Bundle + CI (Instrumentation - Sinatra) \n"
cd instrumentation/sinatra
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root
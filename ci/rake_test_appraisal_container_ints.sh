#!/bin/bash

set -e

root=$(pwd)

printf "\nname: Bundle + CI (Instrumentation - Mysql2) \n"
cd instrumentation/mysql2
gem uninstall -aIx bundler
gem install --no-document bundler -v '~> 2.0.2'
bundle install --jobs=3 --retry=3
bundle exec appraisal install
bundle exec appraisal rake test
cd $root

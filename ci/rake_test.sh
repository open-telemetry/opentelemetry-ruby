#!/bin/bash

root=$(pwd)

printf "\nname: Bundle (API) \n"
cd api && gem install --no-document bundler && bundle install --jobs=3 --retry=3
cd $root

printf "\nname: Bundle (SDK) \n"
cd sdk && gem install --no-document bundler && bundle install --jobs=3 --retry=3
cd $root

printf "\nname: Bundle (Jaeger) \n"
cd exporters/jaeger && gem install --no-document bundler && bundle install --jobs=3 --retry=3
cd $root

printf "\nname: CI (API) \n"
cd api && bundle exec rake
cd $root

printf "\nname: CI (SDK) \n"
cd sdk && bundle exec rake
cd $root

printf "\nname: CI (Jaeger) \n"
cd exporters/jaeger && bundle exec rake
cd $root
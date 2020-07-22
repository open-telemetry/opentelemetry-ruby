#!/bin/bash

set -e

printf "\nname: Install rake \n"
gem install --no-document rake

printf "\nname: Release \n"
rake push_release

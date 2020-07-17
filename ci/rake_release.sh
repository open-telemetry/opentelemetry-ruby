#!/bin/bash

printf "\nname: Install rake \n"
gem install --no-document rake

printf "\nname: Release \n"
rake push_release
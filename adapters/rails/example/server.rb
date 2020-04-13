#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Rails'
end

require 'rails'
require 'action_controller/railtie'

class SingleFile < Rails::Application
  config.session_store :cookie_store, :key => '_session'
  config.secret_key_base = '7893aeb3427daf48502ba09ff695da9ceb3c27daf48b0bba09df'
  Rails.logger = Logger.new($stdout)
end

class PagesController < ActionController::Base
  def index
    render inline: "<h1>Hello World!</h1> <p>I'm just a single file Rails application</p>"
  end
end

SingleFile.routes.draw do
  root to: "pages#index"
end

Rack::Server.start app: SingleFile, Port: 4567

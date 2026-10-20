#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

# Initialize OpenTelemetry SDK before loading anything else.
# This must come before requiring sinatra or dice so that the
# instrumentation patches are applied at load time.
# NOTE: dice.rb defines OTel constants (TRACER, METER, etc.) at class-load
# time and requires the SDK to be fully initialized first. Do not move
# `require_relative 'otel'` below `require_relative 'dice'`.
require_relative 'otel'

require 'sinatra/base'
require 'logger'
require_relative 'dice'

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::DEBUG

class DiceApp < Sinatra::Base
  set :bind, '0.0.0.0'
  set :port, ENV.fetch('APPLICATION_PORT', 8080).to_i

  # GET /rolldice?rolls=<n>&player=<name>
  #
  # Query parameters:
  #   rolls  - optional positive integer; defaults to 1
  #   player - optional player name for logging
  get '/rolldice' do
    content_type :json

    rolls_param = params[:rolls]
    player      = params[:player]

    # Validate: must be a number
    unless rolls_param.nil? || rolls_param.match?(/\A-?\d+\z/)
      status 400
      LOGGER.warn "Invalid rolls parameter: #{rolls_param}"
      return { status: 'error', message: 'Parameter rolls must be an integer' }.to_json
    end

    rolls = rolls_param.nil? ? 1 : rolls_param.to_i

    dice = Dice.new

    begin
      result = dice.roll_dice(rolls)
    rescue ArgumentError => e
      LOGGER.error "Failed to roll dice: #{e.message}"
      halt 500
    end

    if player
      LOGGER.debug "#{player} is rolling the dice: #{result}"
    else
      LOGGER.debug "Anonymous player is rolling the dice: #{result}"
    end

    LOGGER.info "Rolled #{rolls} dice: #{result}"

    result.is_a?(Array) ? result.to_json : result.to_s
  end

  run! if app_file == $0
end

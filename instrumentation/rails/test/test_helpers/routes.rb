# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

::Rails.application.routes.draw do
  get '/ok', to: 'example#ok'
  get '/exception', to: 'example#ok'
  get '/redirection', to: 'example#ok'
end

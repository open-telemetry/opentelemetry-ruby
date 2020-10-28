# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

ROUTES = {
  '/ok' => 'example#ok'
}.freeze

::Rails.application.routes.draw do
  ROUTES.each do |k, v|
    get k, to: v
  end
end

def draw_routes(rails_app, routes: ROUTES)
  rails_app.routes.draw do
    routes.each do |k, v|
      get k, to: v
    end
  end
end

# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExampleController < ActionController::Base
  include ::Rails.application.routes.url_helpers

  def ok
    render plain: 'actually ok'
  end
end

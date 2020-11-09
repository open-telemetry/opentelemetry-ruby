# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExceptionsController < ActionController::Base
  def show
    render plain: 'oops', status: :internal_server_error
  end
end

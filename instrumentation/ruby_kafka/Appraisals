# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

appraise 'ruby-kafka-1.3.0' do
  gem 'ruby-kafka', '~> 1.3.0'
end

# Producer test is timing out on Ruby 3
if RUBY_VERSION < '3'
  appraise 'ruby-kafka-1.2.0' do
    gem 'ruby-kafka', '~> 1.2.0'
  end

  appraise 'ruby-kafka-1.0.0' do
    gem 'ruby-kafka', '~> 1.0.0'
  end
end

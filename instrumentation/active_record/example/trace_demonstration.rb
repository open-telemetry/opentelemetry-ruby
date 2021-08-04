# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Inspired by the bug report template for Active Record
# https://github.com/rails/rails/blob/v6.0.0/guides/bug_report_templates/active_record_gem.rb

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'activerecord'
  gem 'sqlite3'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-active_record'
end

require 'active_record'

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
  end
end

# Simple AR model
class Post < ActiveRecord::Base
  has_many :comments
end

# Simple AR model
class Comment < ActiveRecord::Base
  belongs_to :post
end

Post.create
Comment.create

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../api/lib/opentelemetry/version'
require 'thor'

class InstrumentationGenerator < Thor::Group
  include Thor::Actions

  source_root File.dirname(__FILE__)
  argument :instrumentation_name

  def root_files
    template('templates/rubocop.yml.tt', "#{instrumentation_path}/.rubocop.yml")
    template('templates/yardopts.tt', "#{instrumentation_path}/.yardopts")
    template('templates/Appraisals', "#{instrumentation_path}/Appraisal")
    template('templates/CHANGELOG.md.tt', "#{instrumentation_path}/CHANGELOG.md")
    template('templates/Gemfile', "#{instrumentation_path}/Gemfile")
    template('templates/LICENSE', "#{instrumentation_path}/LICENSE")
    template('templates/gemspec.tt', "#{instrumentation_path}/#{instrumentation_gem_name}.gemspec")
    template('templates/Rakefile', "#{instrumentation_path}/Rakefile")
    template('templates/Readme.md.tt', "#{instrumentation_path}/README.md")
  end

  def lib_files
    template('templates/lib/entrypoint.rb', "#{instrumentation_path}/lib/#{instrumentation_gem_name}.rb")
    template('templates/lib/instrumentation.rb.tt', "#{instrumentation_path}/lib/opentelemetry/instrumentation.rb")
    template('templates/lib/instrumentation/instrumentation_name.rb.tt', "#{instrumentation_path}/lib/opentelemetry/instrumentation/#{instrumentation_name}.rb")
    template('templates/lib/instrumentation/instrumentation_name/instrumentation.rb.tt', "#{instrumentation_path}/lib/opentelemetry/instrumentation/#{instrumentation_name}/instrumentation.rb")
    template('templates/lib/instrumentation/instrumentation_name/version.rb.tt', "#{instrumentation_path}/lib/opentelemetry/instrumentation/#{instrumentation_name}/version.rb")
  end

  def test_files
    template('templates/test/test_helper.rb', "#{instrumentation_path}/test/test_helper.rb")
    template('templates/test/instrumentation.rb', "#{instrumentation_path}/test/#{instrumentation_path}/instrumentation_test.rb")
  end

  private

  def opentelemetry_version
    OpenTelemetry::VERSION
  end

  def instrumentation_path
    "instrumentation/#{instrumentation_name}"
  end

  def instrumentation_gem_name
    "opentelemetry-instrumentation-#{instrumentation_name}"
  end

  def pascal_cased_instrumentation_name
    instrumentation_name.split('_').collect(&:capitalize).join
  end
end

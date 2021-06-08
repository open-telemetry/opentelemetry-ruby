# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../api/lib/opentelemetry/version'
require_relative '../instrumentation/base/lib/opentelemetry/instrumentation/version'
require 'thor'

class InstrumentationGenerator < Thor::Group
  include Thor::Actions

  source_root File.dirname(__FILE__)
  argument :instrumentation_name

  def root_files
    template('templates/rubocop.yml.tt', "#{instrumentation_path}/.rubocop.yml")
    template('templates/yardopts.tt', "#{instrumentation_path}/.yardopts")
    template('templates/Appraisals', "#{instrumentation_path}/Appraisals")
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
    template('templates/test/.rubocop.yml', "#{instrumentation_path}/test/.rubocop.yml")
    template('templates/test/test_helper.rb', "#{instrumentation_path}/test/test_helper.rb")
    template('templates/test/instrumentation.rb', "#{instrumentation_path}/test/opentelemetry/#{instrumentation_path}/instrumentation_test.rb")
  end

  def add_to_releases
    release_details = <<-HEREDOC
  - name: #{instrumentation_gem_name}
    directory: #{instrumentation_path}
    version_constant: [OpenTelemetry, Instrumentation, #{pascal_cased_instrumentation_name}, VERSION]\n
    HEREDOC

    insert_into_file('.toys/.data/releases.yml', release_details, after: "gems:\n")
  end

  def add_to_instrumentation_all
    instrumentation_all_path = 'instrumentation/all'
    gemfile_text = "\ngem '#{instrumentation_gem_name}', path: '../#{instrumentation_name}'"
    insert_into_file("#{instrumentation_all_path}/Gemfile", gemfile_text, after: "gemspec\n")

    gemspec_text = "\n  spec.add_dependency '#{instrumentation_gem_name}', '~> 0.0.0'"
    insert_into_file("#{instrumentation_all_path}/opentelemetry-instrumentation-all.gemspec", gemspec_text, after: "spec.required_ruby_version = '>= 2.5.0'\n")

    all_rb_text = "\nrequire '#{instrumentation_gem_name}'"
    insert_into_file("#{instrumentation_all_path}/lib/opentelemetry/instrumentation/all.rb", all_rb_text, after: "# SPDX-License-Identifier: Apache-2.0\n")
  end

  private

  def opentelemetry_version
    OpenTelemetry::VERSION
  end

  def instrumentation_base_version
    OpenTelemetry::Instrumentation::VERSION
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

  def humanized_instrumentation_name
    instrumentation_name.split('_').collect(&:capitalize).join(' ')
  end
end

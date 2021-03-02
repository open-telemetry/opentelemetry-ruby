# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'erb'

task :update_registry_instrumentations do
  website_repo_dir = ARGV[1] || "../opentelemetry.io"

  # Load all gemspecs
  gemspec_files = Dir.glob("instrumentation/*/opentelemetry-*.gemspec")
  gem_specifications = gemspec_files.map { |gemspec_file|
    Gem::Specification.load(gemspec_file)
  }

  # Define template via ERB
  raw_template = <<-TEMPLATE
---
title: <%= title %>
registryType: instrumentation
isThirdParty: false
language: ruby
tags:
  - ruby
  - instrumentation
repo: <%= repo %>
license: Apache 2.0
description: <%= description %>
authors: OpenTelemetry Authors
otVersion: latest
---
TEMPLATE
  template = ERB.new(raw_template)

  # Within the website repo directory, generate and save all .md files
  Dir.chdir(website_repo_dir) do
    gem_specifications.each do |gem_specification|
      # Set local variables for use in template
      if gem_specification.summary =~ /^(.* instrumentation)/
        title = $1.sub(/instrumentation/, 'Instrumentation')
      else
        raise "Could not infer Title from gem spec summary #{gem_specification.summary}"
      end
      repo = gem_specification.metadata['source_code_uri']
      raise "Could not find repo for #{gem_specification.name}" unless repo
      gem_specification.description =~ /^.* instrumentation/
      description = $& + " for Ruby."

      # Generate .md file, relying on local variables in the current binding
      md_contents = template.result(binding)

      # Write to the website repo directory
      slug = gem_specification.name.sub(/opentelemetry-instrumentation-/, '').gsub(/_/, '-')
      destination = "./content/en/registry/instrumentation-ruby-#{slug}.md"
      File.open(destination, 'w') do |f|
        f << md_contents
      end
    end
  end
end

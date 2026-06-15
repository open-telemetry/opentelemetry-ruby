# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
#
# rake generate:constants
#
# Downloads the upstream opentelemetry-configuration JSON Schema (YAML format)
# and regenerates lib/opentelemetry/constants/generated_constants.rb from it.
#
# Usage:
#   bundle exec rake generate:constants
#   bundle exec rake generate:constants SCHEMA_VERSION=v1.0.0-rc.3
#   bundle exec rake generate:constants SCHEMA_DIR=/path/to/local/schema

require 'fileutils'
require 'open-uri'
require 'tmpdir'
require 'zlib'
require 'stringio'
require 'yaml'
require 'rubygems/package'

SCHEMA_VERSION = ENV.fetch('SCHEMA_VERSION', 'v1.0.0-rc.3')
SCHEMA_TARBALL = "https://api.github.com/repos/open-telemetry/opentelemetry-configuration/tarball/#{SCHEMA_VERSION}"
OUTPUT_FILE    = File.expand_path('../opentelemetry/constants/generated_constants.rb', __dir__)

# ---------------------------------------------------------------------------
# Pure-Ruby tarball downloader/extractor (no curl/wget/tar dependency)
# ---------------------------------------------------------------------------
module SchemaDownloader
  # Downloads the gzip tarball at +url+ and extracts every file under a
  # top-level +schema/+ directory into +dest_dir+, flattening the leading
  # "<repo>-<sha>/" path component that GitHub tarballs include.
  def self.fetch_schema(url, dest_dir)
    FileUtils.mkdir_p(dest_dir)

    raw = URI.open(url, 'rb', 'User-Agent' => 'opentelemetry-otelconfig-generator').read # rubocop:disable Security/Open
    gz  = Zlib::GzipReader.new(StringIO.new(raw))

    Gem::Package::TarReader.new(gz) do |tar|
      tar.each do |entry|
        next unless entry.file?

        rel = entry.full_name.split('/', 2).last
        next unless rel&.start_with?('schema/')

        File.binwrite(File.join(dest_dir, File.basename(rel)), entry.read)
      end
    end

    dest_dir
  end
end

# ---------------------------------------------------------------------------
# Schema loader: merges the split schema files into one flat $defs table and
# resolves the file-level $ref aliases (e.g. `Resource: { $ref: resource.yaml }`).
# ---------------------------------------------------------------------------
module SchemaReader
  ROOT_FILE = 'opentelemetry_configuration.yaml'

  def self.load_yaml(path)
    YAML.safe_load(File.read(path))
  end

  # Returns a single Hash mapping every definition name to its schema body.
  def self.build_defs(schema_dir)
    file_roots = {}
    defs = {}

    Dir.glob(File.join(schema_dir, '*.yaml')).each do |f|
      next if File.basename(f).start_with?('meta_schema')

      doc = load_yaml(f)
      next unless doc.is_a?(Hash)

      file_roots[File.basename(f)] = doc
      (doc['$defs'] || {}).each { |name, body| defs[name] = body }
    end

    root = file_roots.fetch(ROOT_FILE, {})

    # Resolve `Name: { $ref: some_file.yaml }` aliases to the file's root schema.
    (root['$defs'] || {}).each do |name, body|
      next unless body.is_a?(Hash) && body['$ref'].is_a?(String) && body['$ref'].end_with?('.yaml')

      target = file_roots[body['$ref']]
      defs[name] = target if target
    end

    # The root configuration object itself.
    defs['OpenTelemetryConfiguration'] = root.reject { |k, _| k == '$defs' }
    defs
  end
end

# ---------------------------------------------------------------------------
# Code generator: schema $defs → Ruby Struct definitions (purely schema-driven)
# ---------------------------------------------------------------------------
module ConstantsGenerator
  module_function

  # Ruby Struct members must be valid identifiers. Schema keys like
  # "detection/development" become "detection_development".
  def field_name(key)
    key.gsub(%r{[/.\-]}, '_').gsub(/[^a-zA-Z0-9_]/, '_')
  end

  # Extracts the definition name from a $ref string, or nil.
  # Handles "#/$defs/Foo" and "common.yaml#/$defs/Foo".
  def ref_name(schema)
    return nil unless schema.is_a?(Hash)

    ref = schema['$ref']
    return nil unless ref.is_a?(String) && ref.include?('#/$defs/')

    ref.split('#/$defs/').last
  end

  # A definition becomes a generated Struct when it declares (non-empty) properties.
  def struct?(defs, name)
    body = defs[name]
    body.is_a?(Hash) && body['properties'].is_a?(Hash) && !body['properties'].empty?
  end

  # A "marker" is an empty object (no properties, no enum, additionalProperties
  # not a map) — its presence is meaningful, its value is nil/{} (e.g. console:,
  # always_on:, tracecontext:). These map to a presence boolean.
  def marker?(defs, name)
    body = defs[name]
    return false unless body.is_a?(Hash)
    return false if body['properties']
    return false if body['enum']

    add = body['additionalProperties']
    object_type = body['type'] == 'object' || (body['type'].is_a?(Array) && body['type'].include?('object'))
    object_type && (add == false || add.nil?)
  end

  def array_schema?(prop)
    Array(prop['type']).include?('array') || prop.key?('items')
  end

  # Ruby expression that builds the value for one property given local var `h`.
  def value_expr(prop, defs, key)
    direct = ref_name(prop)

    if direct && struct?(defs, direct)
      "#{direct}.from_hash(h['#{key}'])"
    elsif direct && marker?(defs, direct)
      "h.key?('#{key}')"
    elsif array_schema?(prop)
      item_ref = ref_name(prop['items'] || {})
      if item_ref && struct?(defs, item_ref)
        "Array(h['#{key}']).filter_map { |e| #{item_ref}.from_hash(e) }"
      else
        "h['#{key}']"
      end
    else
      "h['#{key}']"
    end
  end

  def render_struct(name, body, defs)
    props = body['properties']
    members = props.keys.map { |k| ":#{field_name(k)}" }.join(",\n  ")

    assignments = props.map do |key, prop|
      "      #{field_name(key)}: #{value_expr(prop, defs, key)}"
    end.join(",\n")

    <<~RUBY
      #{name} = Struct.new(
        #{members},
        keyword_init: true
      ) do
        def self.from_hash(h)
          return nil unless h.is_a?(Hash)

          new(
      #{assignments}
          )
        end
      end
    RUBY
  end

  def generate(defs)
    names = defs.keys.select { |n| struct?(defs, n) }.sort
    parts = [header(names.size)]
    names.each { |name| parts << render_struct(name, defs[name], defs) }
    parts.join("\n")
  end

  def header(count)
    <<~RUBY
      # frozen_string_literal: true

      # Copyright The OpenTelemetry Authors
      # SPDX-License-Identifier: Apache-2.0
      #
      # DO NOT EDIT — generated by `bundle exec rake generate:constants`
      # Schema: open-telemetry/opentelemetry-configuration #{SCHEMA_VERSION}
      # Structs: #{count} (one per object definition in the schema)
      # To regenerate: bundle exec rake generate:constants

    RUBY
  end
end

# ---------------------------------------------------------------------------
# Rake tasks
# ---------------------------------------------------------------------------
namespace :generate do
  desc "Download OTel configuration schema (#{SCHEMA_VERSION}) and regenerate lib/opentelemetry/constants/generated_constants.rb"
  task :constants do
    schema_dir = ENV['SCHEMA_DIR']

    if schema_dir
      puts "Using local schema directory: #{schema_dir}"
    else
      tmpdir = Dir.mktmpdir('otel-schema-')
      schema_dir = File.join(tmpdir, 'schema')

      puts "Downloading schema #{SCHEMA_VERSION} from GitHub..."
      begin
        SchemaDownloader.fetch_schema(SCHEMA_TARBALL, schema_dir)
      rescue StandardError => e
        abort "Failed to download schema: #{e.class}: #{e.message}"
      end

      puts "Schema extracted to #{schema_dir}"
    end

    puts 'Loading and merging schema files...'
    defs = SchemaReader.build_defs(schema_dir)
    object_count = defs.keys.count { |n| ConstantsGenerator.struct?(defs, n) }
    puts "Found #{defs.size} definitions (#{object_count} object structs)."

    puts 'Generating constants...'
    output = ConstantsGenerator.generate(defs)

    FileUtils.mkdir_p(File.dirname(OUTPUT_FILE))
    File.write(OUTPUT_FILE, output)
    puts "Written to #{OUTPUT_FILE}"
  end
end

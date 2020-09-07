# frozen_string_literal: true

desc "Generate initial settings file"

long_desc \
  "This tool generates an initial settings file for this repo." \
    " You will generally need to make additional edits to this file after" \
    " initial generation."

required_arg :repo do
  desc "GitHub repo owner and name (e.g. dazuma/toys)"
end

flag :yes, "--yes", "-y" do
  desc "Automatically answer yes to all confirmations"
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  file_path = ::File.join(::File.dirname(__dir__), ".data", "releases.yml")
  if ::File.readable?(file_path)
    puts "Cannot overwrite existing file: #{file_path}", :red, :bold
    exit(1)
  end
  return unless yes || confirm("Create file #{file_path}? ", default: true)
  ::File.open(file_path, "w") do |file|
    write_settings(file)
  end
  puts("Wrote initial settings file: #{file_path}.", :green, :bold)
end

def write_settings(file)
  file.puts("repo: #{repo}")
  file.puts("# Insert additional repo-level settings here.")
  file.puts
  file.puts("gems:")
  ::Dir.glob("**/*.gemspec").each do |gemspec|
    gem_name = ::File.basename(gemspec, ".gemspec")
    file.puts("  - name: #{gem_name}")
    dir = ::File.dirname(gemspec)
    file.puts("    directory: #{dir}") if dir != gem_name
    file.puts("    # Insert additional gem-level settings here.")
  end
end

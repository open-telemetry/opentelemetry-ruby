# frozen_string_literal: true

desc "Generate GitHub Actions workflow files"

long_desc \
  "This tool generates workflow files for GitHub Actions."

flag :yes, "--yes", "-y" do
  desc "Automatically answer yes to all confirmations"
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

# Context for ERB templates
class ErbContext
  def initialize(settings)
    @settings = settings
  end

  def self.get(settings)
    new(settings).instance_eval { binding }
  end
end

def run
  require "erb"
  require "release_utils"

  @utils = ReleaseUtils.new(self)
  unless @utils.enable_release_automation?
    puts "Release automation disabled in settings."
    unless yes || confirm("Create workflow files anyway? ", default: false)
      @utils.error("Aborted.")
    end
  end

  @workflows_dir = ::File.join(context_directory, ".github", "workflows")
  files = [
    "release-on-closed.yml",
    "release-on-push.yml",
    "release-perform.yml",
    "release-request.yml",
  ]

  files.each { |name| generate(name) }
end

def generate(name)
  destination = ::File.join(@workflows_dir, name)
  if ::File.readable?(destination)
    puts "Destination file #{destination} exists.", :yellow, :bold
    return unless yes || confirm("Overwrite? ", default: true)
  else
    return unless yes || confirm("Create file #{destination}? ", default: true)
  end

  template_path = find_data("templates/#{name}.erb")
  raise "Unable to find template #{name}.erb" unless template_path
  erb = ::ERB.new(::File.read(template_path))

  ::File.open(destination, "w") do |file|
    file.write(erb.result(ErbContext.get(@utils.repo_settings)))
    puts "Wrote #{destination}.", :green, :bold
  end
end

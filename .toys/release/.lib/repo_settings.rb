# frozen_string_literal: true

class RepoSettings
  def initialize(info, tool_context)
    @tool_context = tool_context
    @warnings = []
    read_global_info(info)
    read_gem_info(info)
  end

  attr_reader :repo_path
  attr_reader :main_branch
  attr_reader :default_gem

  attr_reader :required_checks_regexp
  attr_reader :release_jobs_regexp
  attr_reader :required_checks_timeout

  attr_reader :docs_builder_tool

  def repo_owner
    repo_path.split("/").first
  end

  def signoff_commits?
    @signoff_commits
  end

  def enable_release_automation?
    @enable_release_automation
  end

  def coordinate_versions?
    @coordinate_versions
  end

  def all_gems
    @gems.keys
  end

  def gem_info(gem_name, key = nil)
    info = @gems[gem_name]
    key ? info[key] : info
  end

  def gem_directory(gem_name, from: :context)
    path = gem_info(gem_name, "directory")
    case from
    when :context
      path
    when :absolute
      ::File.expand_path(path, @tool_context.context_directory)
    else
      raise "Unknown from value: #{from.inspect}"
    end
  end

  def gem_cd(gem_name, &block)
    dir = gem_directory(gem_name, from: :absolute)
    ::Dir.chdir(dir, &block)
  end

  def gem_changelog_path(gem_name, from: :directory)
    path = gem_info(gem_name, "changelog_path")
    case from
    when :directory
      path
    when :context
      ::File.expand_path(path, gem_directory(gem_name))
    when :absolute
      ::File.expand_path(path, gem_directory(gem_name, from: :absolute))
    else
      raise "Unknown from value: #{from.inspect}"
    end
  end

  def gem_version_rb_path(gem_name, from: :directory)
    path = gem_info(gem_name, "version_rb_path")
    case from
    when :directory
      path
    when :context
      ::File.expand_path(path, gem_directory(gem_name))
    when :absolute
      ::File.expand_path(path, gem_directory(gem_name, from: :absolute))
    else
      raise "Unknown from value: #{from.inspect}"
    end
  end

  def gem_version_constant(gem_name)
    gem_info(gem_name, "version_constant")
  end

  def release_pending_label
    "release: pending"
  end

  def release_error_label
    "release: error"
  end

  def release_aborted_label
    "release: aborted"
  end

  def release_complete_label
    "release: complete"
  end

  def release_related_label?(name)
    !(/^release:\s/ =~ name).nil?
  end

  def release_branch_name(gem_name)
    "#{@release_branch_prefix}/#{gem_name}"
  end

  def multi_release_branch_name
    timestamp = ::Time.now.strftime("%Y%m%d%H%M%S")
    "#{@release_branch_prefix}/multi/#{timestamp}"
  end

  def gem_name_from_release_branch(ref)
    match = %r{^#{@release_branch_prefix}/([^/]+)$}.match(ref)
    match ? match[1] : nil
  end

  def release_related_branch?(ref)
    %r{^#{@release_branch_prefix}/([^/]+|multi/\d+)$}.match(ref) ? true : false
  end

  private

  def read_global_info(info)
    @main_branch = info["main_branch"] || "main"
    @repo_path = info["repo"]
    @signoff_commits = info["signoff_commits"] ? true : false
    @coordinate_versions = info["coordinate_versions"] ? true : false
    @docs_builder_tool = info["docs_builder_tool"]
    @enable_release_automation = info["enable_release_automation"] != false
    required_checks = info["required_checks"]
    @required_checks_regexp = required_checks == false ? nil : ::Regexp.new(required_checks.to_s)
    @required_checks_timeout = info["required_checks_timeout"] || 900
    @release_jobs_regexp = ::Regexp.new(info["release_jobs_regexp"] || "^release-")
    @release_branch_prefix = info["release_branch_prefix"] || "release"
  end

  def read_gem_info(info)
    @gems = {}
    @default_gem = nil
    has_multiple_gems = info["gems"].size > 1
    info["gems"].each do |gem_info|
      add_gem_defaults(gem_info, has_multiple_gems)
      name = check_gem_info(gem_info)
      @gems[name] = gem_info
      @default_gem ||= name
    end
  end

  def add_gem_defaults(gem_info, has_multiple_gems)
    name = gem_info["name"]
    gem_info["directory"] ||= has_multiple_gems ? name : "."
    segments = name.split("-")
    name_path = segments.join("/")
    gem_info["version_rb_path"] ||= "lib/#{name_path}/version.rb"
    gem_info["changelog_path"] ||= "CHANGELOG.md"
    gem_info["version_constant"] ||= segments.map { |seg| camelize(seg) } + ["VERSION"]
    gem_info["gh_pages_directory"] ||= has_multiple_gems ? name : "."
    gem_info["gh_pages_version_var"] ||=
      has_multiple_gems ? "version_#{name}".tr("-", "_") : "version"
  end

  def check_gem_info(gem_info)
    name = gem_info["name"]
    raise "Name missing from gem in releases.yml" unless name
    dir = ::File.expand_path(gem_info["directory"], @tool_context.context_directory)
    raise "Missing directory #{dir} for gem #{name}" unless ::File.directory?(dir)
    gemspec = ::File.expand_path("#{name}.gemspec", dir)
    raise "Missing gemspec file #{gemspec}" unless ::File.file?(gemspec)
    changelog = ::File.expand_path(gem_info["changelog_path"], dir)
    raise "Missing changelog #{changelog} for gem #{name}" unless ::File.file?(changelog)
    check_version_file(gem_info, name, dir)
    name
  end

  def check_version_file(gem_info, name, dir)
    version_file = ::File.expand_path(gem_info["version_rb_path"], dir)
    raise "Missing version file #{version_file} for gem #{name}" unless ::File.file?(version_file)
    script = "load #{version_file.inspect}; p " + gem_info["version_constant"].join("::")
    @tool_context.ruby(["-e", script], out: :null)
  end

  def camelize(str)
    str.to_s
       .sub(/^_/, "")
       .sub(/_$/, "")
       .gsub(/_+/, "_")
       .gsub(/(?:^|_)([a-zA-Z])/) { ::Regexp.last_match(1).upcase }
  end
end

# frozen_string_literal: true

class RepoSettings
  def initialize(info, tool_context)
    @tool_context = tool_context
    @warnings = []
    @errors = []
    read_global_info(info)
    read_commit_lint_info(info)
    read_gem_info(info)
    check_global_info
    check_gem_info
  end

  attr_reader :warnings
  attr_reader :errors

  attr_reader :repo_path
  attr_reader :main_branch
  attr_reader :git_user_name
  attr_reader :git_user_email
  attr_reader :default_gem

  attr_reader :required_checks_regexp
  attr_reader :release_jobs_regexp
  attr_reader :required_checks_timeout

  attr_reader :docs_builder_tool

  attr_reader :commit_lint_merge
  attr_reader :commit_lint_allowed_types

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

  def commit_lint_fail_checks?
    @commit_lint_fail_checks
  end

  def commit_lint_active?
    @commit_lint_active
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
      ::File.join(gem_directory(gem_name), path)
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
      ::File.join(gem_directory(gem_name), path)
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
    @git_user_name = info["git_user_name"]
    @git_user_email = info["git_user_email"]
  end

  def read_commit_lint_info(info)
    info = info["commit_lint"]
    @commit_lint_active = !info.nil?
    info = {} unless info.is_a?(::Hash)
    @commit_lint_fail_checks = info["fail_checks"] ? true : false
    @commit_lint_merge = Array(info["merge"] || ["squash", "merge", "rebase"])
    @commit_lint_allowed_types = info["allowed_types"]
    if @commit_lint_allowed_types
      @commit_lint_allowed_types = Array(@commit_lint_allowed_types).map(&:downcase)
    end
  end

  def read_gem_info(info)
    @gems = {}
    @default_gem = nil
    has_multiple_gems = info["gems"].size > 1
    info["gems"].each do |gem_info|
      name = gem_info["name"]
      unless name
        @errors << "Name missing from gem in releases.yml"
        next
      end
      add_gem_defaults(name, gem_info, has_multiple_gems)
      @gems[name] = gem_info
      @default_gem ||= name
    end
  end

  def add_gem_defaults(name, gem_info, has_multiple_gems)
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

  def check_global_info
    @errors << "Repo key missing from releases.yml" unless @repo_path
  end

  def check_gem_info
    @errors << "No gems listed in releases.yml" if @gems.empty?
    @gems.each do |name, gem_info|
      check_gem_directory_contents(name, gem_info)
    end
  end

  def check_gem_directory_contents(name, gem_info)
    dir = ::File.expand_path(gem_info["directory"], @tool_context.context_directory)
    @errors << "Missing directory #{dir} for gem #{name}" unless ::File.directory?(dir)
    gemspec = ::File.expand_path("#{name}.gemspec", dir)
    @errors << "Missing gemspec file #{gemspec}" unless ::File.file?(gemspec)
    changelog = ::File.expand_path(gem_info["changelog_path"], dir)
    @errors << "Missing changelog file #{changelog} for gem #{name}" unless ::File.file?(changelog)
    version_file = ::File.expand_path(gem_info["version_rb_path"], dir)
    unless ::File.file?(version_file)
      @errors << "Missing version file #{version_file} for gem #{name}"
    end
    version_constant = gem_info["version_constant"].join("::")
    script = "load #{version_file.inspect}; p #{version_constant}"
    unless @tool_context.ruby(["-e", script], out: :null, e: false).success?
      @errors << "Version file #{version_file} for gem #{name} didn't define #{version_constant}"
    end
  end

  def camelize(str)
    str.to_s
       .sub(/^_/, "")
       .sub(/_$/, "")
       .gsub(/_+/, "_")
       .gsub(/(?:^|_)([a-zA-Z])/) { ::Regexp.last_match(1).upcase }
  end
end

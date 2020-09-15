# frozen_string_literal: true

require "forwardable"
require "json"
require "yaml"
require "repo_settings"

class ReleaseUtils
  class ReleaseError < ::StandardError
    def initialize(message, more_messages)
      super(message)
      @more_messages = more_messages
    end

    attr_reader :more_messages

    def all_messages
      [message] + more_messages
    end
  end

  def initialize(tool_context)
    @raise_on_error = false
    @tool_context = tool_context
    @logger = @tool_context.logger
    load_repo_settings
    ensure_gh_binary
    ensure_git_binary
  end

  extend ::Forwardable

  def_delegators :@repo_settings,
                 :repo_path, :repo_owner, :main_branch, :default_gem,
                 :required_checks_regexp, :release_jobs_regexp, :required_checks_timeout,
                 :docs_builder_tool, :signoff_commits?, :enable_release_automation?,
                 :coordinate_versions?
  def_delegators :@repo_settings,
                 :all_gems, :gem_info,
                 :gem_directory, :gem_cd,
                 :gem_changelog_path, :gem_version_rb_path, :gem_version_constant
  def_delegators :@repo_settings,
                 :release_pending_label, :release_error_label, :release_aborted_label,
                 :release_complete_label, :release_related_label?,
                 :release_branch_name, :multi_release_branch_name,
                 :gem_name_from_release_branch, :release_related_branch?

  attr_reader :tool_context
  attr_reader :logger
  attr_reader :repo_settings
  attr_accessor :raise_on_error

  def current_sha(ref = nil)
    capture(["git", "rev-parse", ref || "HEAD"]).strip
  end

  def current_branch
    branch = capture(["git", "branch", "--show-current"]).strip
    branch.empty? ? nil : branch
  end

  def git_remote_url(remote)
    capture(["git", "remote", "get-url", remote]).strip
  end

  def exec(cmd, **opts, &block)
    tool_context.exec(cmd, **opts, &block)
  end

  def capture(cmd, **opts, &block)
    tool_context.capture(cmd, **opts, &block)
  end

  def ensure_gh_binary
    result = exec(["gh", "--version"], out: :capture, exit_on_nonzero_status: false)
    match = /^gh version (\d+)\.(\d+)\.(\d+)/.match(result.captured_out.to_s)
    if !result.success? || !match
      error("gh not installed.",
            "See https://cli.github.com/manual/installation for installation instructions.")
    end
    version_val = match[1].to_i * 1_000_000 + match[2].to_i * 1000 + match[3].to_i
    version_str = "#{match[1]}.#{match[2]}.#{match[3]}"
    if version_val < 10_000
      error("gh version 0.10 or later required but #{version_str} found.",
            "See https://cli.github.com/manual/installation for installation instructions.")
    end
    logger.info("gh version #{version_str} found")
    self
  end

  def ensure_git_binary
    result = exec(["git", "--version"], out: :capture, exit_on_nonzero_status: false)
    match = /^git version (\d+)\.(\d+)\.(\d+)/.match(result.captured_out.to_s)
    if !result.success? || !match
      error("git not installed.",
            "See https://git-scm.com/downloads for installation instructions.")
    end
    version_val = match[1].to_i * 1_000_000 + match[2].to_i * 1000 + match[3].to_i
    version_str = "#{match[1]}.#{match[2]}.#{match[3]}"
    if version_val < 2_022_000
      error("git version 2.22 or later required but #{version_str} found.",
            "See https://git-scm.com/downloads for installation instructions.")
    end
    logger.info("git version #{version_str} found")
    self
  end

  def find_release_prs(gem_name: nil, merge_sha: nil, label: nil)
    label ||= release_pending_label
    args = {
      state: merge_sha ? "closed" : "open",
      sort: "updated",
      direction: "desc",
      per_page: 20,
    }
    if gem_name
      args[:head] = "#{repo_owner}:#{release_branch_name(gem_name)}"
      args[:sort] = "created"
    end
    query = args.map { |k, v| "#{k}=#{v}" }.join("&")
    output = capture(["gh", "api", "repos/#{repo_path}/pulls?#{query}",
                      "-H", "Accept: application/vnd.github.v3+json"])
    prs = ::JSON.parse(output)
    if merge_sha
      prs.find do |pr_info|
        pr_info["merged_at"] && pr_info["merge_commit_sha"] == merge_sha &&
          pr_info["labels"].any? { |label_info| label_info["name"] == label }
      end
    else
      prs.find_all do |pr_info|
        pr_info["labels"].any? { |label_info| label_info["name"] == label }
      end
    end
  end

  def load_pr(pr_number)
    result = exec(["gh", "api", "repos/#{repo_path}/pulls/#{pr_number}",
                   "-H", "Accept: application/vnd.github.v3+json"],
                  out: :capture, exit_on_nonzero_status: false)
    return nil unless result.success?
    ::JSON.parse(result.captured_out)
  end

  def update_release_pr(pr_number, label: nil, message: nil, state: nil, cur_pr: nil)
    update_pr_label(pr_number, label, cur_pr: cur_pr) if label
    update_pr_state(pr_number, state, cur_pr: cur_pr) if state
    add_pr_message(pr_number, message) if message
    self
  end

  def update_pr_label(pr_number, label, cur_pr: nil)
    cur_pr ||= load_pr(pr_number)
    cur_labels = cur_pr["labels"].map { |label_info| label_info["name"] }
    release_labels, other_labels = cur_labels.partition { |name| name.start_with? "release: " }
    return if release_labels == [label]
    body = ::JSON.dump(labels: other_labels + [label])
    exec(["gh", "api", "-XPATCH", "repos/#{repo_path}/issues/#{pr_number}",
          "--input", "-", "-H", "Accept: application/vnd.github.v3+json"],
         in: [:string, body], out: :null)
    self
  end

  def update_pr_state(pr_number, state, cur_pr: nil)
    cur_pr ||= load_pr(pr_number)
    return if cur_pr["state"] == state
    body = ::JSON.dump(state: state)
    exec(["gh", "api", "-XPATCH", "repos/#{repo_path}/pulls/#{pr_number}",
          "--input", "-", "-H", "Accept: application/vnd.github.v3+json"],
         in: [:string, body], out: :null)
    self
  end

  def add_pr_message(pr_number, message)
    body = ::JSON.dump(body: message)
    exec(["gh", "api", "repos/#{repo_path}/issues/#{pr_number}/comments",
          "--input", "-", "-H", "Accept: application/vnd.github.v3+json"],
         in: [:string, body], out: :null)
    self
  end

  def current_library_version(gem_name)
    path = gem_version_rb_path(gem_name, from: :absolute)
    require path
    const = ::Object
    gem_version_constant(gem_name).each do |name|
      const = const.const_get(name)
    end
    const
  end

  def verify_library_version(gem_name, gem_vers)
    logger.info("Verifying #{gem_name} version file ...")
    lib_vers = current_library_version(gem_name)
    if gem_vers == lib_vers
      logger.info("Version file OK")
    else
      path = gem_version_rb_path(gem_name, from: :absolute)
      error("Requested version #{gem_vers} doesn't match #{gem_name} library version #{lib_vers}.",
            "Modify #{path} and set VERSION = #{gem_vers.inspect}")
    end
    lib_vers
  end

  def verify_changelog_content(gem_name, gem_vers) # rubocop:disable Metrics/MethodLength
    logger.info("Verifying #{gem_name} changelog content...")
    changelog_path = gem_changelog_path(gem_name, from: :context)
    today = ::Time.now.strftime("%Y-%m-%d")
    entry = []
    state = :start
    ::File.readlines(changelog_path).each do |line|
      case state
      when :start
        if line =~ %r{^### v#{::Regexp.escape(gem_vers)} / \d\d\d\d-\d\d-\d\d\n$}
          entry << line
          state = :during
        elsif line =~ /^### /
          error("The first changelog entry in #{changelog_path} isn't for version #{gem_vers}.",
                "It should start with:",
                "### v#{gem_vers} / #{today}",
                "But it actually starts with:",
                line)
        end
      when :during
        if line =~ /^### /
          state = :after
        else
          entry << line
        end
      end
    end
    if entry.empty?
      error("The changelog #{changelog_path} doesn't have any entries.",
            "The first changelog entry should start with:",
            "### v#{gem_vers} / #{today}")
    else
      logger.info("Changelog OK")
    end
    entry.join
  end

  def verify_repo_identity(git_remote: "origin")
    logger.info("Verifying git repo identity ...")
    url = git_remote_url(git_remote)
    cur_repo =
      case url
      when %r{^git@github.com:([^/]+/[^/]+)\.git$}
        ::Regexp.last_match(1)
      when %r{^https://github.com/([^/]+/[^/]+)/?$}
        ::Regexp.last_match(1)
      else
        error("Unrecognized remote url: #{url.inspect}")
      end
    if cur_repo == repo_path
      logger.info("Git repo is correct.")
    else
      error("Remmote repo is #{cur_repo}, expected #{repo_path}")
    end
    cur_repo
  end

  def verify_git_clean
    logger.info("Verifying git clean...")
    output = capture(["git", "status", "-s"]).strip
    if output.empty?
      logger.info("Git working directory is clean.")
    else
      error("There are local git changes that are not committed.")
    end
    self
  end

  def verify_github_checks(ref: nil)
    if required_checks_regexp.nil?
      logger.info("GitHub checks disabled")
      return self
    end
    ref = current_sha(ref)
    logger.info("Verifying GitHub checks ...")
    errors = github_check_errors(ref)
    error(*errors) unless errors.empty?
    logger.info("GitHub checks all passed.")
    self
  end

  def wait_github_checks(ref: nil)
    if required_checks_regexp.nil?
      logger.info("GitHub checks disabled")
      return self
    end
    wait_github_checks_internal(current_sha(ref), ::Time.now.to_i + required_checks_timeout)
  end

  def github_check_errors(ref)
    result = exec(["gh", "api", "repos/#{repo_path}/commits/#{ref}/check-runs",
                   "-H", "Accept: application/vnd.github.antiope-preview+json"],
                  out: :capture, e: false)
    return ["Failed to obtain GitHub check results for #{ref}"] unless result.success?
    checks = ::JSON.parse(result.captured_out)["check_runs"]
    results = []
    results << "No GitHub checks found for #{ref}" if checks.empty?
    checks.each do |check|
      name = check["name"]
      next if release_jobs_regexp.match(name) || !required_checks_regexp.match(name)
      if check["status"] != "completed"
        results << "GitHub check #{name.inspect} is not complete"
      elsif check["conclusion"] != "success"
        results << "GitHub check #{name.inspect} was not successful"
      end
    end
    results
  end

  def log(message)
    logger.info(message)
  end

  def error(message, *more_messages)
    if ::ENV["GITHUB_ACTIONS"]
      loc = caller_locations(1).first
      puts("::error file=#{loc.path},line=#{loc.lineno}::#{message}")
    else
      tool_context.puts(message, :red, :bold)
    end
    more_messages.each { |m| tool_context.puts(m, :red) }
    raise ReleaseError.new(message, more_messages) if raise_on_error
    sleep(1)
    tool_context.exit(1)
  end

  def warning(message, *more_messages)
    if ::ENV["GITHUB_ACTIONS"]
      loc = caller_locations(1).first
      puts("::warning file=#{loc.path},line=#{loc.lineno}::#{message}")
    else
      tool_context.puts(message, :yellow, :bold)
    end
    more_messages.each { |m| tool_context.puts(m, :yellow) }
  end

  private

  def load_repo_settings
    file_path = tool_context.find_data("releases.yml")
    error("Unable to find releases.yml data file") unless file_path
    info = ::YAML.load_file(file_path)
    @repo_settings = RepoSettings.new(info, @tool_context)
    error("Repo key missing from releases.yml") unless @repo_settings.repo_path
    error("No gems listed in releases.yml") unless @repo_settings.default_gem
  end

  def wait_github_checks_internal(ref, deadline)
    interval = 10
    loop do
      logger.info("Polling GitHub checks ...")
      errors = github_check_errors(ref)
      if errors.empty?
        logger.info("GitHub checks all passed.")
        return []
      end
      errors.each { |msg| logger.info(msg) }
      if ::Time.now.to_i > deadline
        results = ["GitHub checks still failing after #{required_checks_timeout} secs."]
        return results + errors
      end
      logger.info("Sleeping for #{interval} secs ...")
      sleep(interval)
      interval += 10 unless interval >= 60
    end
  end
end

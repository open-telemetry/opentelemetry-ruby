# frozen_string_literal: true

require "fileutils"
require "release_utils"

class ReleaseRequester
  class GemInfo
    def initialize(utils, gem_name, override_version, release_ref)
      @utils = utils
      @gem_name = gem_name
      @override_version = override_version
      @release_ref = release_ref
      @last_version = @new_version = @date = @full_changelog = @changelog_entries = nil
      @modified = false
      verify_gem_name
      init_analysis
      determine_last_version
      analyze_messages
      determine_new_version
      build_changelog_entries
    end

    attr_reader :gem_name
    attr_reader :last_version
    attr_reader :new_version
    attr_reader :changelog_entries
    attr_reader :date
    attr_reader :full_changelog

    def update_new_version(new_version)
      raise "Full changelog already built" if @full_changelog
      new_version = ::Gem::Version.new(new_version) unless new_version.is_a?(::Gem::Version)
      if @override_version && new_version.to_s != @override_version
        @utils.error("Mismatch between coordinated version #{new_version} and" \
                     " #{@gem_name} override version #{@override_version}")
      end
      @new_version = new_version
    end

    def build_full_changelog(date: nil)
      raise "Full changelog already built" if @full_changelog
      @date = date || ::Time.now.strftime("%Y-%m-%d")
      entries = @changelog_entries.empty? ? ["* (No significant changes)"] : @changelog_entries
      body = entries.join("\n")
      @full_changelog = "### v#{@new_version} / #{@date}\n\n#{body}"
    end

    def modify_files
      return false if @modified
      build_full_changelog unless @full_changelog
      modify_version_file
      modify_changelog_file
      @modified = true
    end

    private

    SEMVER_CHANGES = {
      "patch" => 2,
      "minor" => 1,
      "major" => 0,
    }.freeze

    def verify_gem_name
      @utils.error("Gem #{@gem_name} not known.") unless @utils.gem_info(@gem_name)
      prs = @utils.find_release_prs(gem_name: @gem_name)
      return if prs.empty?
      pr_number = prs.first["number"]
      @utils.error("A release PR ##{pr_number} already exists for #{@gem_name}")
    end

    def init_analysis
      @bump_segment = 2
      @feats = []
      @fixes = []
      @docs = []
      @breaks = []
      @others = []
    end

    def determine_last_version
      @last_version =
        @utils.capture(["git", "tag", "-l"])
              .split("\n")
              .map do |tag|
                if tag =~ %r{^#{@gem_name}/v(\d+\.\d+\.\d+)$}
                  ::Gem::Version.new(::Regexp.last_match(1))
                end
              end
              .compact
              .max
      if @last_version
        @utils.log("Last release tag of #{@gem_name} was for version #{@last_version}")
      else
        @utils.log("Could not find any previous releases for #{@gem_name}")
      end
    end

    def analyze_messages
      unless @last_version
        @others << "Initial release."
        return
      end
      @utils.log("Analyzing commit messages since last version ...")
      dir = @utils.gem_directory(@gem_name)
      dir = "#{dir}/" unless dir.end_with?("/")
      commits = "#{@gem_name}/v#{@last_version}..#{@release_ref}"
      @utils.capture(["git", "log", commits, "--format=%H"]).split("\n").reverse_each do |sha|
        unless dir == "./"
          files = @utils.capture(["git", "diff", "--name-only", "#{sha}^..#{sha}"])
          next unless files.split("\n").any? { |file| file.start_with?(dir) }
        end
        message = @utils.capture(["git", "log", "#{sha}^..#{sha}", "--format=%B"])
        analyze_message message
      end
    end

    def analyze_message(message)
      lines = message.split("\n")
      return if lines.empty?
      bump_segment = analyze_title(lines.first)
      bump_segment = analyze_body(lines[1..-1], bump_segment)
      @bump_segment = bump_segment if bump_segment < @bump_segment
    end

    def analyze_title(title)
      bump_segment = 2
      match = /^(fix|feat|docs)(?:\([^()]+\))?(!?):\s+(.*)$/.match(title)
      return bump_segment unless match
      description = normalize_line(match[3], delete_pr_number: true)
      case match[1]
      when "fix"
        @fixes << description
      when "docs"
        @docs << description
      when "feat"
        @feats << description
        bump_segment = 1 if bump_segment > 1
      end
      if match[2] == "!"
        bump_segment = 0
        @breaks << description
      end
      bump_segment
    end

    def analyze_body(body, bump_segment)
      footers = body.reduce nil do |list, line|
        if line.empty?
          []
        elsif list
          list << line
        end
      end
      lock_change = false
      return bump_segment unless footers
      footers.each do |line|
        match = /^(BREAKING CHANGE|[\w-]+):\s+(.*)$/.match(line)
        next unless match
        case match[1]
        when /^BREAKING[-\s]CHANGE$/
          bump_segment = 0 unless lock_change
          @breaks << normalize_line(match[2])
        when /^semver-change$/i
          seg = SEMVER_CHANGES[match[2].downcase]
          if seg
            bump_segment = seg
            lock_change = true
          end
        end
      end
      bump_segment
    end

    def normalize_line(line, delete_pr_number: false)
      match = /^([a-z])(.*)$/.match(line)
      line = match[1].upcase + match[2] if match
      line = line.gsub(/\(#\d+\)$/, "") if delete_pr_number
      line
    end

    def determine_new_version
      if @override_version
        new_version = @override_version
        @utils.log("New version of #{@gem_name} is overridden to #{new_version}")
      elsif @last_version
        segments = @last_version.segments
        @bump_segment = 1 if segments[0].zero? && @bump_segment.zero?
        segments[@bump_segment] += 1
        new_version = segments.fill(0, @bump_segment + 1).join(".")
        @utils.log("New version of #{@gem_name} is #{new_version} by commit message analysis")
      else
        new_version = "0.1.0"
        @utils.log("New version of #{@gem_name} is #{new_version} as the initial version")
      end
      @new_version = ::Gem::Version.new(new_version)
    end

    def build_changelog_entries
      @changelog_entries = []
      unless @breaks.empty?
        @breaks.each do |line|
          @changelog_entries << "* BREAKING CHANGE: #{line}"
        end
        @changelog_entries << ""
      end
      @feats.each do |line|
        @changelog_entries << "* ADDED: #{line}"
      end
      @fixes.each do |line|
        @changelog_entries << "* FIXED: #{line}"
      end
      @docs.each do |line|
        @changelog_entries << "* DOCS: #{line}"
      end
      @others.each do |line|
        @changelog_entries << "* #{line}"
      end
    end

    def modify_version_file
      path = @utils.gem_version_rb_path(@gem_name, from: :context)
      @utils.log("Modifying version file #{path}")
      content = ::File.read(path)
      original_content = content.dup
      changed = content.sub!(/  VERSION\s*=\s*(["'])\d+\.\d+\.\d+(?:\.\w+)*["']/,
                             "  VERSION = \\1#{@new_version}\\1")
      @utils.error("Could not find VERSION constant for #{@gem_name} in #{path}") unless changed
      if content == original_content
        @utils.warning("Version constant for #{@gem_name} is already #{@new_version}.")
        return
      end
      ::File.open(path, "w") { |file| file.write(content) }
    end

    def modify_changelog_file
      path = @utils.gem_changelog_path(@gem_name, from: :context)
      @utils.log("Modifying changelog file #{path}")
      content = ::File.read(path)
      if content =~ %r{\n### v#{@new_version} / \d\d\d\d-\d\d-\d\d\n}
        @utils.warning("Changelog entry for #{@gem_name} #{@new_version} already seems to exist.")
        return
      end
      changed = content.sub!(%r{\n### (v\d+\.\d+\.\d+ / \d\d\d\d-\d\d-\d\d)\n},
                             "\n#{@full_changelog}\n\n### \\1\n")
      unless changed
        content << "\n" until content.end_with?("\n\n")
        content << @full_changelog << "\n"
      end
      ::File.open(path, "w") { |file| file.write(content) }
    end
  end

  def initialize(utils,
                 release_ref: nil,
                 git_remote: nil,
                 coordinate_versions: nil,
                 prune_gems: false)
    @utils = utils
    @release_ref = release_ref || @utils.current_branch || @utils.main_branch
    @git_remote = git_remote || "origin"
    @coordinate_versions = coordinate_versions
    @coordinate_versions = @utils.coordinate_versions? if @coordinate_versions.nil?
    @prune_gems = prune_gems
    @gem_info_list = []
    @performed_initial_setup = false
    @pr_number = nil
  end

  attr_reader :gem_info_list

  def empty?
    @gem_info_list.empty?
  end

  def initial_setup
    @utils.error("Releases must be requested from an existing branch") unless @release_ref
    @utils.verify_git_clean
    @utils.verify_repo_identity(git_remote: @git_remote)
    @utils.verify_github_checks(ref: @release_ref)
    if @utils.capture(["git", "rev-parse", "--is-shallow-repository"]).strip == "true"
      @utils.exec(["git", "fetch", "--unshallow", @git_remote, @release_ref])
    end
    @utils.exec(["git", "fetch", @git_remote, "--tags"])
    @utils.git_set_user_info
    @utils.exec(["git", "checkout", @release_ref])
    @performed_initial_setup = true
  end

  def gem_info(gem_name, override_version: nil)
    raise "Gem list is already finished" if @gem_info_list.frozen?
    if @gem_info_list.any? { |gem_info| gem_info.gem_name == gem_name }
      @utils.error("Gem #{gem_name} listed multiple times in release request")
    end
    initial_setup unless @performed_initial_setup
    info = GemInfo.new(@utils, gem_name, override_version, @release_ref)
    @gem_info_list << info
    info
  end

  def finish_gems
    raise "Gem list is already finished" if @gem_info_list.frozen?
    @utils.log("Starting with #{@gem_info_list.size} gems in the release list")
    prune_gem_list if @prune_gems
    coordinate_gem_versions if @coordinate_versions
    date = ::Time.now.strftime("%Y-%m-%d")
    @gem_info_list.each { |info| info.build_full_changelog(date: date) }
    @gem_info_list.freeze
    self
  end

  def create_pull_request
    raise "Already created PR" if @pr_number
    finish_gems unless @gem_info_list.frozen?
    @gem_info_list.each(&:modify_files)
    determine_commit_info
    create_release_commit
    create_release_pr
    @pr_number
  end

  private

  def prune_gem_list
    if @coordinate_versions
      if @gem_info_list.all? { |info| info.changelog_entries.empty? }
        @utils.warning("All gems were removed because no changes were detected")
        @gem_info_list.clear
      end
    else
      @gem_info_list.delete_if { |info| info.changelog_entries.empty? }
      @utils.log("#{@gem_info_list.size} gems remain after pruning those with no changes")
    end
  end

  def coordinate_gem_versions
    max_version = @gem_info_list.map(&:new_version).max
    @utils.log("Coordinating versions: setting all versions to #{max_version}")
    @gem_info_list.each { |info| info.update_new_version(max_version) }
  end

  def determine_commit_info
    if @gem_info_list.size == 1
      info = @gem_info_list.first
      @release_commit_title = "release: Release #{info.gem_name} #{info.new_version}"
      @release_branch_name = @utils.release_branch_name(info.gem_name)
    else
      @release_commit_title = "release: Release #{@gem_info_list.size} gems"
      @release_branch_name = @utils.multi_release_branch_name
    end
  end

  def create_release_commit
    if @utils.capture(["git", "diff"]).strip.empty?
      @utils.error("No changes to make. Are you sure the version to release is correct?")
    end
    check_branch_cmd = ["git", "rev-parse", "--verify", "--quiet", @release_branch_name]
    if @utils.exec(check_branch_cmd, e: false).success?
      @utils.exec(["git", "branch", "-D", @release_branch_name])
    end
    @utils.exec(["git", "checkout", "-b", @release_branch_name])
    commit_cmd = ["git", "commit", "-a", "-m", @release_commit_title]
    commit_cmd << "--signoff" if @utils.signoff_commits?
    @utils.exec(commit_cmd)
    @utils.exec(["git", "push", "-f", @git_remote, @release_branch_name])
    @utils.exec(["git", "checkout", @release_ref])
  end

  def create_release_pr
    enable_automation = @utils.enable_release_automation?
    pr_body = enable_automation ? build_automation_pr_body : build_standalone_pr_body
    body = ::JSON.dump(title: @release_commit_title,
                       head: @release_branch_name,
                       base: @release_ref,
                       body: pr_body,
                       maintainer_can_modify: true)
    response = @utils.capture(["gh", "api", "repos/#{@utils.repo_path}/pulls", "--input", "-",
                               "-H", "Accept: application/vnd.github.v3+json"],
                              in: [:string, body])
    pr_info = ::JSON.parse(response)
    @pr_number = pr_info["number"]
    return unless enable_automation
    @utils.update_release_pr(@pr_number, label: @utils.release_pending_label, cur_pr: pr_info)
  end

  def build_automation_pr_body
    <<~STR
      #{build_pr_body_header}

       *  To confirm this release, merge this pull request, ensuring the \
          #{@utils.release_pending_label.inspect} label is set. The release \
          script will trigger automatically on merge.
       *  To abort this release, close this pull request without merging.

      #{build_pr_body_footer}
    STR
  end

  def build_standalone_pr_body
    <<~STR
      #{build_pr_body_header}

      You can run the `release perform` script once these changes are merged.

      #{build_pr_body_footer}
    STR
  end

  def build_pr_body_header
    lines = [
      "This pull request prepares new gem releases for the following gems:",
      "",
    ]
    @gem_info_list.each do |info|
      gem_line = " *  **#{info.gem_name} #{info.new_version}**"
      gem_line += info.last_version ? " (was #{info.last_version})" : " (initial release)"
      lines << gem_line
    end
    lines << ""
    lines <<
      "For each gem, this pull request modifies the gem version and provides" \
        " an initial changelog entry based on" \
        " [conventional commit](https://conventionalcommits.org) messages." \
        " You can edit these changes before merging, to release a different" \
        " version or to alter the changelog text."
    lines.join("\n")
  end

  def build_pr_body_footer
    lines = ["The generated changelog entries have been copied below:"]
    @gem_info_list.each do |info|
      lines << ""
      lines << "----"
      lines << ""
      lines << "## #{info.gem_name}"
      lines << ""
      lines << info.full_changelog.strip
    end
    lines.join("\n")
  end
end

# frozen_string_literal: true

desc "Open a release request"

long_desc \
  "This tool opens release pull requests for the specified gems. It analyzes" \
  "the commits since the last release, and updates each gem's version and" \
    " changelog accordingly. This tool is normally called from a GitHub" \
    " Actions workflow, but can also be executed locally.",
  "",
  "When invoked, this tool first performs checks including:",
  "* The git workspace must be clean (no new, modified, or deleted files)",
  "* The remote repo must be the correct repo configured in releases.yml",
  "* All GitHub checks for the release commit must have succeeded",
  "",
  "The tool then creates release pull requests for each gem:",
  "* It collects all commit messages since the previous release.",
  "* It builds a changelog using properly formatted conventional commit" \
    " messages of type 'fix', 'feat', and 'docs', and any that indicate a" \
    " breaking change.",
  "* Unless a specific version is provided via flags, it infers a new version" \
    " number using the implied semver significance of the commit messages.",
  "* It edits the changelog and version Ruby files and pushes a commit to a" \
    " release branch.",
  "* It opens a release pull request.",
  "",
  "Release pull requests may be edited to modify the version and/or changelog" \
    " before merging. In repositories that have release automation enabled," \
    " the release script will run automatically when a release pull request" \
    " is merged."

flag :coordinate_versions, "--[no-]coordinate-versions" do
  desc "Cause all gems to release with the same version"
end
flag :gems, "--gems=VAL" do
  accept(/^([\w-]+(:[\w\.-]+)?([\s,]+[\w-]+(:[\w\.-]+)?)*)?$/)
  desc "Gems and versions to release"
  long_desc \
    "Specify a list of gems and optional versions. The format is a list of" \
      " comma and/or whitespace delimited strings of the form:",
    ["    <gemname>[:<version>]"],
    "",
    "If no version is specified for a gem, a version is inferred from the" \
      " conventional commit messages. If this flag is omitted or left blank," \
      " all gems in the repository that have at least one commit of type" \
      " 'fix', 'feat', or 'docs', or a breaking change, will be released.",
    "",
    "You can also use the special gem name 'all' which forces release of all" \
      " gems in the repository regardless of whether they have significant" \
      " changes. You can also supply a version with 'all' to release all gems" \
      " with the same version."
end
flag :git_remote, "--git-remote=VAL" do
  default "origin"
  desc "The name of the git remote"
  long_desc \
    "The name of the git remote pointing at the canonical repository." \
    " Defaults to 'origin'."
end
flag :release_ref, "--release-ref=VAL" do
  desc "Target branch for the release"
  long_desc \
    "The target branch for the release request. Defaults to the current" \
      " branch."
end
flag :yes, "--yes", "-y" do
  desc "Automatically answer yes to all confirmations"
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  require "release_utils"
  require "release_requester"

  ::Dir.chdir(context_directory)
  @utils = ReleaseUtils.new(self)

  [:release_ref].each do |key|
    set(key, nil) if get(key).to_s.empty?
  end

  @requester = populate_requester
  @requester.finish_gems
  if @requester.empty?
    @utils.error("Did not find any gems ready to release based on commit history.",
                 "You can force the release of a gem by listing it explicitly.")
  end
  confirmation_ui
  @requester.create_pull_request
end

def populate_requester
  requester = ReleaseRequester.new(@utils,
                                   release_ref: release_ref,
                                   git_remote: git_remote,
                                   coordinate_versions: coordinate_versions,
                                   prune_gems: gems.to_s.empty?)
  gem_list = gems.to_s.empty? ? @utils.all_gems : gems.split(/[\s,]+/)
  gem_list.each do |entry|
    gem_name, override_version = entry.split(":", 2)
    if gem_name == "all"
      @utils.all_gems.each do |name|
        requester.gem_info(name, override_version: override_version)
      end
    else
      requester.gem_info(gem_name, override_version: override_version)
    end
  end
  requester
end

def confirmation_ui
  puts("Opening a request to release the following gems:", :bold)
  @requester.gem_info_list.each do |info|
    puts("* #{info.gem_name} version #{info.last_version} -> #{info.new_version}")
  end
  unless yes || confirm("Create release PR? ", :bold, default: true)
    @utils.error("Release aborted")
  end
end

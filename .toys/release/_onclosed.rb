# frozen_string_literal: true

desc "Process a release pull request"

long_desc \
  "This tool is called by a GitHub Actions workflow after a release pull" \
    " request is closed. If the pull request was merged, the requested" \
    " release is performed and the pull request is updated with the results." \
    " If the pull request was closed without being merged, the pull request" \
    " is marked as aborted. This tool also ensures that release branches are" \
    " deleted once their PRs are closed."

flag :enable_releases, "--enable-releases=VAL" do
  default "true"
  desc "Control whether to enable releases."
  long_desc \
    "If set to 'true', releases will be enabled. Any other value will" \
    " result in dry-run mode, meaning it will go through the motions," \
    " create a GitHub release, and update the release pull request if" \
    " applicable, but will not actually push the gem to Rubygems or push" \
    " the docs to gh-pages."
end
flag :event_path, "--event-path=VAL" do
  default ::ENV["GITHUB_EVENT_PATH"]
  desc "Path to the pull request closed event JSON file"
end
flag :git_user_email, "--git-user-email=VAL" do
  desc "Git user email to use for new commits"
  long_desc \
    "Git user email to use for docs commits. If not provided, uses the" \
    " current global git setting. Required if there is no global setting."
end
flag :git_user_name, "--git-user-name=VAL" do
  desc "Git user email to use for new commits"
  long_desc \
    "Git user name to use for docs commits. If not provided, uses the" \
    " current global git setting. Required if there is no global setting."
end
flag :rubygems_api_key, "--rubygems-api-key=VAL" do
  desc "Set the Rubygems API key"
  long_desc \
    "Use the given Rubygems API key when pushing to Rubygems. Required if" \
    " and only if there is no current setting in the home Rubygems configs."
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  require "release_utils"

  [:git_user_email, :git_user_name, :rubygems_api_key].each do |key|
    set(key, nil) if get(key).to_s.empty?
  end

  ::Dir.chdir(context_directory)
  @utils = ReleaseUtils.new(self)

  @utils.error("GitHub event path missing") unless event_path
  @pr_info = ::JSON.parse(::File.read(event_path))["pull_request"]

  delete_release_branch
  check_for_release_pr
  if @pr_info["merged_at"]
    handle_release_merged
  else
    handle_release_aborted
  end
end

def delete_release_branch
  source_ref = @pr_info["head"]["ref"]
  if @utils.release_related_branch?(source_ref)
    logger.info("Deleting release branch #{source_ref} ...")
    exec(["git", "push", "--delete", "origin", source_ref], exit_on_nonzero_status: false)
    logger.info("Deleted.")
  end
end

def check_for_release_pr
  pr_number = @pr_info["number"]
  if @pr_info["labels"].all? { |label_info| label_info["name"] != @utils.release_pending_label }
    logger.info("PR #{pr_number} does not have the release pending label. Ignoring.")
    exit
  end
end

def handle_release_aborted
  pr_number = @pr_info["number"]
  logger.info("Updating release PR #{pr_number} to mark it as aborted.")
  @utils.update_release_pr(pr_number,
                           label: @utils.release_aborted_label,
                           message: "Release PR closed without merging.",
                           state: "closed",
                           cur_pr: @pr_info)
  logger.info "Done."
end

def handle_release_merged
  setup_git
  performer = create_performer
  github_check_errors = @utils.wait_github_checks
  if github_check_errors.empty?
    find_gems_and_versions.each do |gem_name, gem_version|
      if performer.instance(gem_name, gem_version).perform
        puts("SUCCESS: Released #{gem_name} #{gem_version}", :bold, :green)
      end
    end
  else
    performer.add_extra_errors(github_check_errors)
  end
  if performer.report_results
    puts("All releases completed successfully", :bold, :green)
  else
    @utils.error("Releases reported failure")
  end
end

def setup_git
  merge_sha = @pr_info["merge_commit_sha"]
  @utils.exec(["git", "fetch", "--depth=2", "origin", "+#{merge_sha}:refs/heads/release/current"])
  @utils.exec(["git", "checkout", "release/current"])
end

def find_gems_and_versions
  gem_name =
    if @utils.all_gems.size == 1
      @utils.default_gem
    else
      @utils.gem_name_from_release_branch(@pr_info["head"]["ref"])
    end
  if gem_name
    gem_version = @utils.current_library_version(gem_name)
    logger.info("Found single gem to release: #{gem_name} #{gem_version}.")
    result = { gem_name => gem_version }
    return result
  end
  gems_and_versions_from_git
end

def gems_and_versions_from_git
  output = @utils.capture(["git", "diff", "--name-only", "release/current^..release/current"])
  files = output.split("\n")
  gems = @utils.all_gems.find_all do |gem_name|
    dir = @utils.gem_directory(gem_name)
    files.any? { |file| file.start_with?(dir) }
  end
  gems.each_with_object({}) do |gem_name, result|
    result[gem_name] = gem_version = @utils.current_library_version(gem_name)
    logger.info("Releasing gem due to file changes: #{gem_name} #{gem_version}.")
  end
end

def create_performer
  require "release_performer"
  dry_run = /^t/i =~ enable_releases.to_s ? false : true
  ReleasePerformer.new(@utils,
                       rubygems_api_key: rubygems_api_key,
                       git_user_name: git_user_name,
                       git_user_email: git_user_email,
                       gh_token: ::ENV["GITHUB_TOKEN"],
                       pr_info: @pr_info,
                       dry_run: dry_run)
end

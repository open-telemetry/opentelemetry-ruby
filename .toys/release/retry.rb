# frozen_string_literal: true

desc "Releases pending gems for a pull request"

long_desc \
  "This tool continues the releases associated with a release pull request." \
    " It is normally used to retry or continue releases that aborted due to" \
    " an error. This tool is normally called from a GitHub Actions workflow," \
    " but can also be executed locally if the proper credentials are present."

required_arg :release_pr, accept: Integer do
  desc "Release pull request number. Required."
end
flag_group desc: "Flags" do
  flag :gh_pages_dir, "--gh-pages-dir=VAL" do
    desc "The directory to use for the gh-pages branch"
    long_desc \
      "Set to the path of a directory to use as the gh-pages workspace when" \
      " building and pushing gem documentation. If left unset, a temporary" \
      " directory will be created (and removed when finished)."
  end
  flag :git_remote, "--git-remote=VAL" do
    default "origin"
    desc "The name of the git remote"
    long_desc \
      "The name of the git remote pointing at the canonical repository." \
      " Defaults to 'origin'."
  end
  flag :rubygems_api_key, "--rubygems-api-key=VAL" do
    desc "Set the Rubygems API key"
    long_desc \
      "Use the given Rubygems API key when pushing to Rubygems. Required if" \
      " and only if there is no current setting in the home Rubygems configs."
  end
  flag :skip_checks, "--[no-]skip-checks" do
    desc "Disable pre-release checks"
    long_desc \
      "If set, all pre-release checks are disabled. This may occasionally be" \
      " useful to repair a broken release, but is generally not recommended."
  end
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
  flag :yes, "--yes", "-y" do
    desc "Automatically answer yes to all confirmations"
  end
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  require "release_utils"
  require "release_performer"

  ::Dir.chdir(context_directory)
  @utils = ReleaseUtils.new(self)

  [:gh_pages_dir, :rubygems_api_key].each do |key|
    set(key, nil) if get(key).to_s.empty?
  end

  verify_release_pr
  setup_git
  perform_pending_releases
  cleanup_git
end

def verify_release_pr
  @pr_info = @utils.load_pr(release_pr)
  @utils.error("Could not load pull request ##{release_pr}") unless @pr_info
  expected_labels = [@utils.release_pending_label, @utils.release_error_label]
  return if @pr_info["labels"].any? { |label| expected_labels.include?(label["name"]) }
  warning = "PR #{release_pr} doesn't have the release pending or release error label."
  if yes
    logger.warn(warning)
    return
  end
  unless confirm("#{warning} Proceed anyway? ", :bold, default: false)
    @utils.error("Release aborted.")
  end
end

def perform_pending_releases
  performer = create_performer
  github_check_errors = @utils.wait_github_checks
  if github_check_errors.empty?
    @utils.released_gems_and_versions(@pr_info).each do |gem_name, gem_version|
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
  @original_branch = @utils.current_branch
  merge_sha = @pr_info["merge_commit_sha"]
  exec(["git", "fetch", "--depth=2", "origin", merge_sha])
  exec(["git", "checkout", merge_sha])
end

def cleanup_git
  exec(["git", "checkout", @original_branch]) if @original_branch
end

def create_performer
  dry_run = /^t/i =~ enable_releases.to_s ? false : true
  ReleasePerformer.new(@utils,
                       skip_checks: skip_checks,
                       rubygems_api_key: rubygems_api_key,
                       git_remote: git_remote,
                       gh_pages_dir: gh_pages_dir,
                       gh_token: ::ENV["GITHUB_TOKEN"],
                       pr_info: @pr_info,
                       check_exists: true,
                       dry_run: dry_run)
end

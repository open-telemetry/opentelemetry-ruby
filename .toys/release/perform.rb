# frozen_string_literal: true

desc "Perform a gem release"

long_desc \
  "This tool performs an official gem release. It is normally called from a" \
    " GitHub Actions workflow, but can also be executed locally if the" \
    " proper credentials are present.",
  "",
  "In most cases, gems should be released using the 'prepare' tool, invoked" \
    " either locally or from GitHub Actions. That tool will automatically" \
    " update the library version and changelog based on the commits since" \
    " the last release, and will open a pull request that you can merge to" \
    " actually perform the release. The 'perform' tool should be used only" \
    " if the version and changelog commits are already committed.",
  "",
  "When invoked, this tool first performs checks including:",
  "* The git workspace must be clean (no new, modified, or deleted files)",
  "* The remote repo must be the correct repo configured in releases.yml",
  "* All GitHub checks for the release to commit must have succeeded",
  "* The gem version and changelog must be properly formatted and must match" \
    " the release version",
  "",
  "The tool then performs the necessary release tasks including:",
  "* Building the gem and pushing it to Rubygems",
  "* Building the docs and pushing it to gh-phages (if applicable)",
  "* Creating a GitHub release and tag"

required_arg :gem_name do
  desc "Name of the gem to release. Required."
end
required_arg :gem_version do
  desc "Version of the gem to release. Required."
end
flag_group desc: "Flags" do
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
  flag :release_sha, "--release-sha=VAL" do
    desc "SHA of the commit to use for the release"
    long_desc \
      "Specifies a particular SHA for the release. Optional. Defaults to the" \
      " current HEAD."
  end
  flag :only, "--only=VAL" do
    accept ["precheck", "gem", "docs", "github-release"]
    desc "Run only one step of the release process."
    long_desc \
      "Cause only one step of the release process to run.",
      "* 'precheck' runs only the pre-release checks.",
      "* 'gem' builds and pushes the gem to Rubygems.",
      "* 'docs' builds and pushes the docs to gh-pages.",
      "* 'github-release' tags and creates a GitHub release.",
      "",
      "Optional. If omitted, all steps are performed."
  end
  flag :release_pr, "--release-pr=VAL" do
    accept ::Integer
    desc "Release pull request number"
    long_desc \
      "Update the given release pull request number. Optional. Normally," \
        " this tool will look for a merged release pull request whose merge" \
        " SHA matches the release SHA. However, if you are releasing from a" \
        " different SHA than the pull request merge SHA, you can specify the" \
        " pull request number explicitly."
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

  [:gh_pages_dir, :git_user_email, :git_user_name, :rubygems_api_key].each do |key|
    set(key, nil) if get(key).to_s.empty?
  end
  set(:release_sha, @utils.current_sha) if release_sha.to_s.empty?

  perform
end

def perform
  performer = create_performer
  confirm_release
  performer.instance(gem_name, gem_version, only: only).perform
  if performer.report_results
    puts("All releases completed successfully", :bold, :green)
  else
    @utils.error("Releases reported failure")
  end
end

def create_performer
  dry_run = /^t/i =~ enable_releases.to_s ? false : true
  ReleasePerformer.new @utils,
                       release_sha: release_sha,
                       skip_checks: skip_checks,
                       rubygems_api_key: rubygems_api_key,
                       git_remote: git_remote,
                       git_user_name: git_user_name,
                       git_user_email: git_user_email,
                       gh_pages_dir: gh_pages_dir,
                       gh_token: ::ENV["GITHUB_TOKEN"],
                       pr_info: find_release_pr,
                       dry_run: dry_run
end

def confirm_release
  return if yes
  return if confirm("Release #{gem_name} #{gem_version}? ", :bold, default: false)
  @utils.error("Release aborted")
end

def find_release_pr
  if release_pr
    pr_info = @utils.load_pr(release_pr)
    @utils.error("Release PR ##{release_pr} not found") unless pr_info
  else
    pr_info = @utils.find_release_prs(merge_sha: release_sha)
  end
  if pr_info
    logger.info("Found release PR #{pr_info['number']}.")
  else
    logger.warn("No release PR found for this release.")
  end
  pr_info
end

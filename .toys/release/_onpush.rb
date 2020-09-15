# frozen_string_literal: true

desc "Update open releases after a push"

long_desc \
  "This tool is called by a GitHub Actions workflow after a commit is pushed" \
    " to a releasable branch. It adds a warning note to any relevant open" \
    " releases that additional commits have been added."

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  require "release_utils"

  ::Dir.chdir(context_directory)
  @utils = ReleaseUtils.new(self)

  pr_info = @utils.find_release_prs(merge_sha: @utils.current_sha)
  if pr_info
    pr_number = pr_info["number"]
    logger.info("This appears to be a merge of release PR ##{pr_number}.")
  else
    logger.info("This was not a merge of a release PR.")
    update_open_release_prs
  end
end

def update_open_release_prs
  push_branch = @utils.current_branch
  logger.info("Searching for open release PRs targeting branch #{push_branch} ...")
  pr_message = nil
  @utils.find_release_prs.each do |pr_info|
    pr_number = pr_info["number"]
    pr_branch = pr_info["base"]["ref"]
    unless pr_branch == push_branch
      logger.info("Skipping PR ##{pr_number} that targets branch #{pr_branch}")
      next
    end
    pr_message ||= build_pr_message
    logger.info("Updating PR #{pr_number} ...")
    @utils.update_release_pr(pr_number, message: pr_message, cur_pr: pr_info)
  end
  if pr_message
    logger.info("Finished updating existing release PRs.")
  else
    logger.info("No existing release PRs target branch #{push_branch}.")
  end
end

def build_pr_message
  commit_message = capture(["git", "log", "-1", "--pretty=%B"])
  <<~STR
    WARNING: An additional commit was added while this release PR was open.
    You may need to add to the changelog, or close this PR and prepare a new one.

    Commit link: https://github.com/#{@utils.repo_path}/commit/#{@utils.current_sha}

    Message:
    #{commit_message}
  STR
end

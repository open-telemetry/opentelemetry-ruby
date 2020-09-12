# frozen_string_literal: true

desc "Create GitHub labels for releases"

long_desc \
  "This tool ensures that the proper GitHub labels are present for the" \
    " release automation scripts."

flag :yes, "--yes", "-y" do
  desc "Automatically answer yes to all confirmations"
end

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true

def run
  require "release_utils"
  require "json"
  require "cgi"

  @utils = ReleaseUtils.new(self)

  unless @utils.enable_release_automation?
    puts "Release automation disabled in settings."
    unless yes || confirm("Create labels anyway? ", default: false)
      @utils.error("Aborted.")
    end
  end

  expected_labels = create_expected_labels
  cur_labels = load_existing_labels
  update_labels cur_labels, expected_labels
end

def create_expected_labels
  [
    {
      "name" => @utils.release_pending_label,
      "color" => "ddeeff",
      "description" => "Automated release is pending",
    },
    {
      "name" => @utils.release_error_label,
      "color" => "ffdddd",
      "description" => "Automated release failed with an error",
    },
    {
      "name" => @utils.release_aborted_label,
      "color" => "eeeeee",
      "description" => "Automated release was aborted",
    },
    {
      "name" => @utils.release_complete_label,
      "color" => "ddffdd",
      "description" => "Automated release completed successfully",
    },
  ]
end

def load_existing_labels
  output = capture(["gh", "api", "repos/#{@utils.repo_path}/labels",
                    "-H", "Accept: application/vnd.github.v3+json"])
  ::JSON.parse(output)
end

def update_labels(cur_labels, expected_labels)
  expected_labels.each do |expected|
    cur = cur_labels.find { |label| label["name"] == expected["name"] }
    if cur
      if cur["color"] != expected["color"] || cur["description"] != expected["description"]
        update_label(expected)
      end
    else
      create_label(expected)
    end
  end
  cur_labels.each do |cur|
    next unless @utils.release_related_label?(cur["name"])
    delete_label(cur) unless expected_labels.find { |label| label["name"] == cur["name"] }
  end
end

def create_label(label)
  label_name = label["name"]
  return unless yes || confirm("Label \"#{label_name}\" doesn't exist. Create? ", default: true)
  body = ::JSON.dump(label)
  exec(["gh", "api", "repos/#{@utils.repo_path}/labels", "--input", "-",
        "-H", "Accept: application/vnd.github.v3+json"],
       in: [:string, body], out: :null)
end

def update_label(label)
  label_name = label["name"]
  return unless yes || confirm("Update fields of \"#{label_name}\"? ", default: true)
  body = ::JSON.dump(color: label["color"], description: label["description"])
  exec(["gh", "api", "-XPATCH", "repos/#{@utils.repo_path}/labels/#{label_name}",
        "--input", "-", "-H", "Accept: application/vnd.github.v3+json"],
       in: [:string, body], out: :null)
end

def delete_label(label)
  label_name = label["name"]
  return unless yes || confirm("Label \"#{label_name}\" unrecognized. Delete? ", default: true)
  exec(["gh", "api", "-XDELETE", "repos/#{@utils.repo_path}/labels/#{label_name}",
        "-H", "Accept: application/vnd.github.v3+json"],
       out: :null)
end

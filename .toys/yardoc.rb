desc "Build YARD documentation for the gem in the current directory"

include :exec, e: true
include :fileutils

set_context_directory Dir.pwd

def run
  raise "No yardopts in the current directory" unless File.file?(".yardopts")
  rm_rf(".yardoc")
  rm_rf("doc")
  exec(["bundle", "update"])
  exec_tool(["yardoc", "_build"])
end

expand :yardoc, name: "_build", bundler: true

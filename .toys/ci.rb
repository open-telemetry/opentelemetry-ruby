desc "Run CI tests across all gems"

flag :check_rubocop do
  desc "Include rubocop checks with tests"
end
flag :check_yard do
  desc "Include yard checks with tests"
end
flag :include_appraisal do
  desc "Run tests on gems that have an appraisal config"
end
flag :include_simple do
  desc "Run tests on gems that do not use appraisal"
end
flag :include_gems, "-I NAME", "--include NAME" do
  default []
  handler :push
  desc "Run tests on the given named gem. Can be used multiple times."
end
flag :exclude_gems, "-X NAME", "--exclude NAME" do
  default []
  handler :push
  desc "Do not run tests on the given named gem. Can be used multiple times."
end

include :exec, e: true
include :terminal, styled: true

def run
  Dir.chdir(context_directory)
  Dir.glob("**/opentelemetry-*.gemspec").sort.each do |gemspec|
    gem_name = File.basename(gemspec, ".gemspec")
    gem_dir = File.dirname(gemspec)
    Dir.chdir(gem_dir) do
      has_appraisal = File.file?("Appraisals")
      handle_gem(gem_name, has_appraisal) if test?(gem_name, has_appraisal)
    end
  end
end

def test?(gem_name, has_appraisal)
  result =
    if exclude_gems.include?(gem_name)
      false
    elsif include_gems.include?(gem_name)
      true
    elsif has_appraisal
      include_appraisal
    else
      include_simple
    end
  if result
    puts "Testing #{gem_name} ...", :cyan, :bold
  else
    puts "Skipping #{gem_name} ...", :yellow, :bold
  end
  result
end

def handle_gem(gem_name, has_appraisal)
  exec(["bundle", "install", "--jobs=3", "--retry=3"])
  if has_appraisal
    exec(["bundle", "exec", "appraisal", "install"])
    exec(["bundle", "exec", "appraisal", "rake", "test"])
  else
    exec(["bundle", "exec", "rake", "test"])
  end
  exec(["bundle", "exec", "rake", "rubocop"]) if check_rubocop
  exec(["bundle", "exec", "rake", "yard"]) if check_yard
end

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

include :exec
include :terminal, styled: true

def run
  @errors = []
  Dir.chdir(context_directory)
  Dir.glob("**/opentelemetry-*.gemspec").sort.each do |gemspec|
    gem_name = File.basename(gemspec, ".gemspec")
    gem_dir = File.dirname(gemspec)
    Dir.chdir(gem_dir) do
      has_appraisal = File.file?("Appraisals")
      handle_gem(gem_name, has_appraisal) if test?(gem_name, has_appraisal)
    end
  end
  final_result
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
    puts("Testing #{gem_name} ...", :cyan, :bold)
  else
    puts("Skipping #{gem_name} ...", :yellow, :bold)
  end
  result
end

def handle_gem(gem_name, has_appraisal)
  individual_test("#{gem_name}: bundle",
                  ["bundle", "install", "--jobs=3", "--retry=3"])
  if has_appraisal
    individual_test("#{gem_name}: appraisal",
                    ["bundle", "exec", "appraisal", "install"])
    individual_test("#{gem_name}: test",
                    ["bundle", "exec", "appraisal", "rake", "test"])
  else
    individual_test("#{gem_name}: test", ["bundle", "exec", "rake", "test"])
  end
  individual_test("#{gem_name}: rubocop",
                  ["bundle", "exec", "rake", "rubocop"]) if check_rubocop
  individual_test("#{gem_name}: yard",
                  ["bundle", "exec", "rake", "yard"]) if check_yard
  individual_test("#{gem_name}: build",
                  ["gem", "build", "#{gem_name}.gemspec"])
end

def individual_test(test_name, cmd)
  puts(test_name, :cyan, :bold)
  unless exec(cmd).success?
    @errors << test_name
    puts("FAILURE", :red, :bold)
  end
end

def final_result
  exit(0) if @errors.empty?
  puts("CI Failures:", :red, :bold)
  @errors.each { |test_name| puts(test_name, :yellow) }
  exit(1)
end

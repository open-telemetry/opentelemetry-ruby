desc "Reinstall Appraisals"

flag :include_gems, "-I NAME", "--include NAME" do
  default []
  handler :push
  desc "Refresh appraisals for the given named gem. Can be used multiple times."
end

include :exec
include :terminal, styled: true

def run
  @errors = []
  Dir.chdir(context_directory)
  Dir.glob("**/opentelemetry-*.gemspec").sort.each do |gemspec|
    gem_name = File.basename(gemspec, ".gemspec")
    gem_dir = File.dirname(gemspec)
    refresh_appraisal(gem_dir) if include_gems.include?(gem_dir) || include_gems.empty?
  end
  final_result
end

def refresh_appraisal(gem_dir)
  Dir.chdir(gem_dir) do
    return unless File.file?("Appraisals")
    unless exec(["bundle", "install", "--jobs=3", "--retry=3"]).success? &&
      exec(["bundle", "exec", "appraisal", "install"]).success?
      @errors << gem_dir
    end
  end
end

def final_result
  exit(0) if @errors.empty?
  puts("Failed to regenerate appraisals:", :red, :bold)
  @errors.each { |gem_name| puts(gem_name, :yellow) }
  exit(1)
end
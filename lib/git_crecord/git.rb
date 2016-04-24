require 'open3'

module GitCrecord
  module Git
    def self.stage(files)
      diff = files.map(&:generate_diff).join("\n")
      content, status = Open3.capture2e(
        'git apply --cached --unidiff-zero - ', stdin_data: diff
      )
      if status != 0
        File.open(File.join(ENV['HOME'], '.git-crecord.log'), 'w') do |file|
          file.write("git apply --cached --unidiff-zero -\n")
          file.write("#{diff}\n")
          file.write("#{diff.lines.size}\n")
          file.write("stdout/stderr:\n#{content}\n")
          file.write("code: #{status}\n")
        end
      end
      status.success?
    end

    def self.commit
      system('git commit')
    end

    def self.diff
      `git diff --no-ext-diff --no-color`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end
  end
end

require_relative 'logger'
require 'open3'

module GitCrecord
  module Git
    def self.stage(files)
      selected_files = files.select(&:selected)
      add_files(selected_files.select{ |file| file.type == :untracked })
      diff = selected_files.map(&:generate_diff).join("\n")
      cmd = 'git apply --cached --unidiff-zero - '
      content, status = Open3.capture2e(cmd, stdin_data: diff)
      LOGGER.info(cmd)
      LOGGER.info(diff)
      LOGGER.info(diff.lines.size)
      LOGGER.info('stdout/stderr:')
      LOGGER.info(content)
      LOGGER.info("return code: #{status}")
      status.success?
    end

    def self.add_files(files)
      files.each do |file|
        success = add_file(file.filename_a)
        raise "could not add file #{file.filename_a}" unless success
      end
    end

    def self.add_file(filename)
      system("git add -N #{filename}")
    end

    def self.status
      `git status --porcelain`
    end

    def self.commit
      exec('git commit')
    end

    def self.diff
      `git diff --no-ext-diff --no-color`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end
  end
end

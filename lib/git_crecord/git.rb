require_relative 'logger'
require 'open3'

module GitCrecord
  module Git
    def self.stage(files)
      diff = files.map(&:generate_diff).join("\n")
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

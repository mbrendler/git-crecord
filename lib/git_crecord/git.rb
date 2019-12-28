# frozen_string_literal: true

require_relative 'logger'
require 'open3'

module GitCrecord
  module Git
    def self.stage_files(files, reverse = false)
      method_name = reverse ? :unstage_steps : :stage_steps
      success = true
      files.each do |file|
        next unless file.selected

        file.send(method_name).each do |step|
          success &&= send(step, file)
        end
      end
      success
    end

    def self.stage(file)
      _stage(file.generate_diff, false)
    end

    def self.unstage(file)
      success = _stage(file.generate_diff, true)
      return false unless success
      return true unless file.type == :new && file.selected == true

      reset_file(file)
    end

    def self._stage(diff, reverse = false)
      cmd = "git apply --cached --unidiff-zero #{reverse ? '-R' : ''} - "
      content, status = Open3.capture2e(cmd, stdin_data: diff)
      LOGGER.info(cmd)
      LOGGER.info(diff)
      LOGGER.info(diff.lines.size)
      LOGGER.info('stdout/stderr:')
      LOGGER.info(content)
      LOGGER.info("return code: #{status}")
      status.success?
    end

    def self.add_file(file)
      system("git add -N #{file.filename_a}")
    end

    def self.add_file_full(file)
      system("git add #{file.filename_a}")
    end

    def self.reset_file(file)
      system("git reset -q #{file.filename_a}")
    end

    def self.status
      `git status --porcelain --untracked-files=all`
    end

    def self.commit
      exec('git commit')
    end

    def self.diff(filename: nil, staged: false)
      filename = "'#{filename}'" if filename
      staged_option = staged ? '--staged' : ''
      `git diff --no-ext-diff --no-color -D #{staged_option} #{filename}`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end

    def self.branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    def self.tab
      @tab ||= ' ' * [2, `git config crecord.tabwidth`.to_i].max
    end
  end
end

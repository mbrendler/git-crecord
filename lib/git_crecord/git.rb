# frozen_string_literal: true

require_relative 'logger'
require 'open3'

module GitCrecord
  module Git
    def self.stage(files, reverse = false)
      selected_files = files.select(&:selected)
      untracked_files = selected_files.select { |file| file.type == :untracked }
      add_files(untracked_files) unless reverse
      diff = selected_files.map(&:generate_diff).join("\n")
      status = _stage(diff, reverse).success?
      return status unless reverse

      reset_files(untracked_files.select { |file| file.selected == true })
      true
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
      status
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

    def self.reset_files(files)
      files.each do |file|
        success = reset_file(file.filename_a)
        raise "could not reset file #{file.filename_a}" unless success
      end
    end

    def self.reset_file(filename)
      system("git reset -q #{filename}")
    end

    def self.status
      `git status --porcelain`
    end

    def self.commit
      exec('git commit')
    end

    def self.diff(staged: false)
      `git diff --no-ext-diff --no-color #{staged ? '--staged' : ''}`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end

    def self.tab
      @tab ||= ' ' * [2, `git config crecord.tabwidth`.to_i].max
    end
  end
end

# frozen_string_literal: true

require_relative 'git_crecord/diff'
require_relative 'git_crecord/git'
require_relative 'git_crecord/ui'
require_relative 'git_crecord/ui/help_window'
require_relative 'git_crecord/version'

module GitCrecord
  def self.main(argv)
    if argv.include?('--version')
      puts VERSION
      true
    elsif argv.include?('--help') || argv.include?('-h')
      help
      true
    else
      run(with_untracked_files: untracked_files?(argv))
    end
  end

  def self.untracked_files?(argv)
    argv.include?('--untracked-files') || argv.include?('-u')
  end

  def self.run(with_untracked_files: false)
    toplevel_dir = Git.toplevel_dir
    return false if toplevel_dir.empty?
    Dir.chdir(toplevel_dir) do
      files = Diff.parse(Git.diff)
      files.concat(Diff.untracked_files(Git.status)) if with_untracked_files
      return false if files.empty?
      result = UI.run(files)
      return result.call == true if result.respond_to?(:call)
      true
    end
  end

  def self.help
    puts <<~HELP
      usage: git crecord [<options>]

        -u, --untracked-files  -- show untracked files
        --version              -- show version information
        -h                     -- this help message

        in-program commands:
      #{UI::HelpWindow::CONTENT.gsub(/^/, '  ')}
    HELP
  end
end

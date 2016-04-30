require_relative 'git_crecord/git'
require_relative 'git_crecord/diff'
require_relative 'git_crecord/ui'
require_relative 'git_crecord/version'
require_relative 'git_crecord/ui/help_window'

module GitCrecord
  def self.main(argv)
    if argv.include?('--version')
      puts VERSION
      true
    elsif argv.include?('--help') || argv.include?('-h')
      help
      true
    else
      run
    end
  end

  def self.run
    Dir.chdir(Git.toplevel_dir) do
      files = Diff.parse(Git.diff)
      files.concat(Diff.untracked_files(Git.status))
      return false if files.empty?
      result = UI.run(files)
      return result.call == true if result.respond_to?(:call)
      true
    end
  end

  def self.help
    puts <<EOS
usage: git crecord [<options>]'

  --version   - show version information'
  -h          - this help message'

  in-program commands:'
#{UI::HelpWindow::CONTENT.gsub(/^/, '  ')}
EOS
  end
end

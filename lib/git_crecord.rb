require_relative 'git_crecord/git'
require_relative 'git_crecord/hunks'
require_relative 'git_crecord/ui'
require_relative 'git_crecord/version'

module GitCrecord
  def self.main(argv)
    if argv.include?('--version')
      puts VERSION
      true
    else
      run
    end
  end

  def self.run
    Dir.chdir(Git.toplevel_dir) do
      files = Hunks.parse(Git.diff)
      files.concat(Hunks.untracked_files(Git.status))
      return false if files.empty?
      result = UI.run(files)
      return result.call == true if result.respond_to?(:call)
      true
    end
  end
end

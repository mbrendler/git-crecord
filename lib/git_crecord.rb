require_relative 'git_crecord/git'
require_relative 'git_crecord/hunks'
require_relative 'git_crecord/ui'

module GitCrecord
  def self.main
    Dir.chdir(Git.toplevel_dir) do
      files = Hunks.parse(Git.diff)
      files.concat(Hunks.untracked_files(Git.status))
      return false if files.empty?
      result = UI.run(files)
      return result.call == true if result.respond_to?(:call)
      0
    end
  end
end

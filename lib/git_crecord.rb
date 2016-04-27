require_relative 'git_crecord/git'
require_relative 'git_crecord/hunks'
require_relative 'git_crecord/ui'

module GitCrecord
  def self.main
    Dir.chdir(Git.toplevel_dir) do
      result = UI.run(Hunks.parse(Git.diff))
      return result.call == true if result.respond_to?(:call)
      0
    end
  end
end

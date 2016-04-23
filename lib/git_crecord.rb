require_relative 'git_crecord/git'
require_relative 'git_crecord/hunks'
require_relative 'git_crecord/ui'

module GitCrecord
  module_function

  def main
    Dir.chdir(Git.toplevel_dir) do
      UI.run(Hunks.parse(Git.diff))
      0
    end
  end
end

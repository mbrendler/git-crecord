require_relative 'git_crecord/git'

module GitCrecord
  module_function

  def main
    Dir.chdir(Git.toplevel_dir) do
      puts Dir.pwd
      0
    end
  end
end

require_relative 'diff/file'

module GitCrecord
  module Diff
    module_function

    def parse(diff)
      files = []
      diff.lines.each do |line|
        line.chomp!
        next if line.start_with?(*%w(index --- +++))
        next files << File.new(*parse_filenames(line)) if file_start?(line)
        next files[-1] << line if hunk_start?(line)
        files[-1].add_hunk_line(line)
      end
      files
    end

    def file_start?(line)
      line.start_with?('diff')
    end

    def hunk_start?(line)
      line.start_with?('@@')
    end

    def parse_filenames(line)
      line.match(%r{a/(.*) b/(.*)$})[1..2]
    end

    def untracked_files(git_status)
      git_status.lines.select{ |l| l.start_with?('??') }.flat_map do |path|
        path = path.chomp[3..-1]
        ::File.directory?(path) ? untracked_dir(path) : untracked_file(path)
      end.compact
    end

    def untracked_file(filename)
      File.new(filename, filename, type: :untracked).tap do |file|
        file_lines = ::File.readlines(filename)
        file << "@@ -0,0 +1,#{file_lines.size} @@"
        file_lines.each{ |line| file.add_hunk_line("+#{line.chomp}") }
        file.selected = false
      end
    end

    def untracked_dir(path)
      Dir.glob(::File.join(path, '**/*')).map do |filename|
        untracked_file(filename)
      end
    end
  end
end

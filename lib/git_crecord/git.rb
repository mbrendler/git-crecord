module GitCrecord
  module Git
# int stage(const Files& files) {
#     logger() << "stage" << std::endl;
#     std::stringstream s;
#     for (auto f : files) {
#         f->generate_diff(s);
#     }
#     FILE* cmd = popen("git apply --cached --unidiff-zero - ", "w");
#     const int rc = fputs(s.str().c_str(), cmd);
#     logger() << "fputs: " << rc << std::endl;
#     logger() << s.str().c_str() << std::endl;
#     const int status_code = pclose(cmd);
#     logger() << "pclose: " << rc << std::endl;
#     return status_code;
# }
#
# int commit() {
#     return system("git commit");
# }
#
# std::string get_diff() {
#     logger() << "get_diff" << std::endl;
#     std::stringstream s;
#     char buffer[1000];
#     FILE* cmd = popen("git diff --no-ext-diff --no-color", "r");
#     while (fgets(buffer, sizeof(buffer) / sizeof(*buffer), cmd)) {
#         s << buffer;
#     }
#     const int rc = pclose(cmd);
#     logger() << "pclose: " << rc << std::endl;
#     return s.str();
# }

    def self.diff
      `git diff --no-ext-diff --no-color`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end

# void cd_toplevel() {
#     const std::string toplevel_dir(get_toplevel_dir());
#     logger() << "toplevel_dir: " << toplevel_dir << std::endl;
#     chdir(toplevel_dir.c_str());
#     char b[PATH_MAX];
#     logger() << "cwd: " << getcwd(b, sizeof(b) / sizeof(*b)) << std::endl;
# }
  end
end

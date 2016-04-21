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

    def self.diff
      `git diff --no-ext-diff --no-color`
    end

    def self.toplevel_dir
      `git rev-parse --show-toplevel`.chomp
    end
  end
end

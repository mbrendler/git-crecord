#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
  bool untracked_files;
  bool reverse;
} Options;

static Options options = {.untracked_files = false, .reverse = false};

static struct option long_options[] = {
    {"untracked", no_argument, 0, 'u'},
    {"reverse", no_argument, 0, 'R'},
    {"help", no_argument, 0, 'h'},
    {0, 0, 0, 0}};

static void options_print_help() {
  puts("usage: git crecord [<options>]");
  puts("");
  puts("  -u, --untracked-files  -- show untracked files");
  puts("  -R, --reverse          -- unstage hunks");
  puts("  --version              -- show version information");
  puts("  -h                     -- this help message");
  puts("");
  puts("  in-program commands:");
  puts("    q      - quit");
  puts("    s      - stage selection and quit");
  puts("    c      - commit selection and quit");
  puts("    P      - print patch");
  puts("    j / ↓  - down");
  puts("    k / ↑  - up");
  puts("    h / ←  - collapse fold");
  puts("    l / →  - expand fold");
  puts("    g      - go to first line");
  puts("    G      - go to last line");
  puts("TODO    C-P    - up to previous hunk / file");
  puts("TODO    C-N    - down to next hunk / file");
  puts("    SPACE  - toggle selection");
  puts("    A      - toggle all selections");
  puts("    ?      - display help");
  puts("    R      - force redraw");
}

Options options_parse(int argc, char *argv[]) {
  int c;
  int option_index = 0;
  while (-1 != (c = getopt_long(argc, argv, "uRh", long_options, &option_index))
  ) {
    switch (c) {
    case 'u':
      options.untracked_files = true;
      break;
    case 'R':
      options.reverse = true;
      break;
    case 'h':
      options_print_help();
      exit(0);
    default:
      break;
    }
  }
  return options;
}

#include <git2.h>
#include <stdio.h>
#include <stdlib.h>

#include "ui.c"

void e(int error) {
  if (error < 0) {
    const git_error *e = git_error_last();
    printf("Error %d/%d: %s\n", error, e->klass, e->message);
    exit(error);
  }
}

const int GIT_STATUS_INDEX_KNOWN_MASK =
    GIT_STATUS_INDEX_NEW | GIT_STATUS_INDEX_MODIFIED |
    GIT_STATUS_INDEX_DELETED | GIT_STATUS_INDEX_RENAMED |
    GIT_STATUS_INDEX_TYPECHANGE;

// GIT_STATUS_CURRENT           0
// GIT_STATUS_INDEX_NEW         A
// GIT_STATUS_INDEX_MODIFIED    M
// GIT_STATUS_INDEX_DELETED     D
// GIT_STATUS_INDEX_RENAMED     R
// GIT_STATUS_INDEX_TYPECHANGE  T
// GIT_STATUS_WT_NEW            A
// GIT_STATUS_WT_MODIFIED       M
// GIT_STATUS_WT_DELETED        D
// GIT_STATUS_WT_TYPECHANGE     T
// GIT_STATUS_WT_RENAMED        R
// GIT_STATUS_IGNORED           I

int status_cb(const char *path, unsigned int status_flags, void *payload) {
  if (status_flags & GIT_STATUS_IGNORED) {
    return 0;
  }
  if (status_flags & GIT_STATUS_WT_NEW) {
    if (status_flags & GIT_STATUS_INDEX_KNOWN_MASK) {
      printf(" A %s\n", path);
    } else {
      printf(" ? %s\n", path);
    }
  } else if (status_flags & GIT_STATUS_WT_MODIFIED) {
    printf(" M %s\n", path);
  }
  return 0;
}

int each_file_cb(const git_diff_delta *delta, float progress, void *payload) {
  printf("File: %s\n", delta->new_file.path);
  return 0;
}

int each_binary_cb(const git_diff_delta *delta, const git_diff_binary *binary,
                   void *payload) {
  printf("Binary File: %s\n", delta->new_file.path);
  return 0;
}

int each_hunk_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
                 void *payload) {
  printf("Hunk: %d,%d -> %d,%d", hunk->old_start, hunk->old_lines,
         hunk->new_start, hunk->new_lines);
  return 0;
}

int each_line_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
                 const git_diff_line *line, void *payload) {
  printf("Line: %c %d,%d %d,%d %.*s", line->origin, line->old_lineno,
         line->new_lineno, line->origin, line->num_lines,
         (int)line->content_len, line->content);
  return 0;
}

int print_cb(const git_diff_delta *delta, const git_diff_hunk *hunk,
             const git_diff_line *line, void *payload) {
  if (line != NULL) {
    printf("Line: %c %d,%d %d,%d %.*s", line->origin, line->old_lineno,
           line->new_lineno, line->origin, line->num_lines,
           (int)line->content_len, line->content);
  } else if (hunk != NULL) {
    printf("Hunk: %d,%d -> %d,%d\n", hunk->old_start, hunk->old_lines,
           hunk->new_start, hunk->new_lines);
  } else {
    printf("Diff: %s\n", delta->new_file.path);
  }
  return 0;
}

int diff_count_number_of_lines(const git_diff_delta *delta,
                               const git_diff_hunk *hunk,
                               const git_diff_line *line, void *payload) {
  if (line) {
    int *counts = (int *)payload;
    counts[0]++;
    if (line->origin == 'F') {
      counts[1]++;
    }
  }
  return 0;
}

int diff_build_ui(const git_diff_delta *delta, const git_diff_hunk *hunk,
                  const git_diff_line *line, void *payload) {
  if (line) {
    ui_add_line(line);
  }
  return 0;
}

int main(int argc, const char *argv[]) {
  atexit(ui_close);

  git_libgit2_init();
  git_repository *repo = NULL;
  e(git_repository_open_ext(&repo, ".", 0, NULL));

  e(git_status_foreach(repo, status_cb, NULL));

  git_diff *diff = NULL;
  e(git_diff_index_to_workdir(&diff, repo, NULL, NULL));
  e(git_diff_foreach(diff, each_file_cb, each_binary_cb, each_hunk_cb,
                     each_line_cb, NULL));

  int counts[2] = {0};
  e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_count_number_of_lines,
                   counts));

  git_reference *head = NULL;
  e(git_repository_head(&head, repo));
  const char *branch = git_reference_shorthand(head);
  ui_init(branch, counts[0], counts[1],
          strcmp(branch, "main") == 0 || strcmp(branch, "master") == 0);

  e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_build_ui, NULL));

  const int value = ui_loop();
  ui_close();
  printf("You pressed: %d\n", value);

  e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, print_cb, NULL));

  git_reference_free(head);
  git_diff_free(diff);

  git_repository_free(repo);
  git_libgit2_shutdown();

  return 0;
}

/* 'cre' is aliased to 'crecord' */
/* usage: git crecord [<options>] */
/*  */
/*   -u, --untracked-files  -- show untracked files */
/*   -R, --reverse          -- unstage hunks */
/*   --version              -- show version information */
/*   -h                     -- this help message */
/*  */
/*   in-program commands: */
/*     q      - quit */
/*     s      - stage selection and quit */
/*     c      - commit selection and quit */
/*     j / ↓  - down */
/*     k / ↑  - up */
/*     h / ←  - collapse fold */
/*     l / →  - expand fold */
/*     f      - toggle fold */
/*     g      - go to first line */
/*     G      - go to last line */
/*     C-P    - up to previous hunk / file */
/*     C-N    - down to next hunk / file */
/*     SPACE  - toggle selection */
/*     A      - toggle all selections */
/*     ?      - display help */
/*     R      - force redraw */

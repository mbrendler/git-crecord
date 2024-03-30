#include <git2.h>
#include <stdio.h>
#include <unistd.h>

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

char status_flags_to_char(uint32_t status_flags) {
  if (status_flags & GIT_STATUS_WT_NEW) {
    if (status_flags & GIT_STATUS_INDEX_KNOWN_MASK) {
      return 'A';
    } else {
      return '?';
    }
  } else if (status_flags & GIT_STATUS_WT_MODIFIED) {
    return 'M';
  }
  return ' ';
}

int status_cb(const char *path, unsigned int status_flags, void *payload) {
  if (0 == (status_flags & GIT_STATUS_IGNORED)) {
    const char status = status_flags_to_char(status_flags);
    printf(" %c %s\n", status, path);
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
    char status_char = ' ';
    if (line->origin == 'F') {
      unsigned status = 0;
      git_status_file(&status, (git_repository *)payload, delta->new_file.path);
      status_char = status_flags_to_char(status);
    }
    ui_add_line(line, delta, status_char);
  }
  return 0;
}

typedef struct {
  unsigned line_index;
  bool hunk_selected;
  FILE *stream;
} DiffPrintPayload;

int diff_print(const git_diff_delta *delta, const git_diff_hunk *hunk,
               const git_diff_line *line, void *payload) {
  DiffPrintPayload *diff_print_payload = payload;
  FILE *stream = diff_print_payload->stream;
  const UiLine *ui_line = ui.lines + diff_print_payload->line_index;
  if (line->origin == 'H') {
    diff_print_payload->hunk_selected = !!ui_line->selected;
    if (ui_line->selected) {
      const UiFile *file = ui_line->file;
      const UiLine *end = file->lines + file->line_count;
      int new_lines = hunk->new_lines;
      for (const UiLine *line_r = ui_line + 1; line_r < end; line_r++) {
        if (line_r->origin == 'H') {
          break;
        }
        if (!line_r->selected) {
          if (line_r->origin == '+') {
            new_lines--;
          } else if (line_r->origin == '-') {
            new_lines++;
          }
        }
      }
      fprintf(stream, "@@ -%d,%d +%d,%d @@\n", hunk->old_start, hunk->old_lines,
              hunk->new_start, new_lines);
    }
  } else {
    if (ui_line->selected ||
        (line->origin == ' ' && diff_print_payload->hunk_selected)) {
      if (line->origin != 'F') {
        fputc(line->origin, stream);
      }
      fwrite(line->content, sizeof(*line->content), line->content_len, stream);
    } else if (line->origin == '-') {
      if (diff_print_payload->hunk_selected) {
        fputc(' ', stream);
        fwrite(line->content, sizeof(*line->content), line->content_len,
               stream);
      }
    }
  }
  diff_print_payload->line_index++;
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

  int counts[2] = {0};
  e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_count_number_of_lines,
                   counts));

  git_reference *head = NULL;
  e(git_repository_head(&head, repo));
  const char *branch = git_reference_shorthand(head);
  ui_init(branch, counts[0], counts[1],
          strcmp(branch, "main") == 0 || strcmp(branch, "master") == 0);

  e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_build_ui, repo));

  const int ui_result_value = ui_loop();
  ui_close();
  switch (ui_result_value) {
  case 'P': {
    DiffPrintPayload payload = {0, false, stdout};
    e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_print, &payload));
    break;
  }
  case 's':
  case 'c': {
    FILE *stage_command_stream =
        popen("git apply --cached --unidiff-zero -", "w");
    DiffPrintPayload payload = {0, false, stage_command_stream};
    e(git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, diff_print, &payload));
    fflush(stage_command_stream);
    pclose(stage_command_stream);
    break;
  }
  }

  ui_free();

  git_reference_free(head);
  git_diff_free(diff);

  git_repository_free(repo);
  git_libgit2_shutdown();

  if ('c' == ui_result_value) {
    execlp("git", "git", "commit", NULL);
  }

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

#include <git2.h>
#include <stdio.h>
#include <unistd.h>

#include "options.c"
#include "ui.c"

void e(int error) {
  if (error < 0) {
    const git_error *e = git_error_last();
    printf("Error %d/%d: %s\n", error, e->klass, e->message);
    exit(error);
  }
}

typedef struct {
  git_repository *repo;
  git_diff *diff;
  unsigned file_count;
  unsigned line_count;
} Program;

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

char file_status_char(git_repository *repo, const char *path) {
  unsigned status_flags = 0;
  git_status_file(&status_flags, repo, path);
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

int diff_count_number_of_lines(
    const git_diff_delta *delta, const git_diff_hunk *hunk,
    const git_diff_line *line, void *payload
) {
  Program *program = payload;
  if (line) {
    program->line_count++;
    if (line->origin == 'F') {
      program->file_count++;
    }
  }
  return 0;
}

typedef struct {
  bool only_untracked;
  char last_file_status;
  Program *program;
} FileSelectionPayload;

int diff_build_ui(
    const git_diff_delta *delta, const git_diff_hunk *hunk,
    const git_diff_line *line, void *payload
) {
  FileSelectionPayload *context = payload;
  if (line) {
    if (line->origin == 'F') {
      context->last_file_status =
          file_status_char(context->program->repo, delta->new_file.path);
    }
    if ((context->only_untracked && context->last_file_status == '?') ||
        (!context->only_untracked && context->last_file_status != '?')) {
      ui_add_line(line, delta, context->last_file_status);
    }
  }
  return 0;
}

typedef struct {
  unsigned line_index;
  bool hunk_selected;
  FileSelectionPayload file_selection;
  FILE *stream;
} DiffPrintPayload;

int diff_print(
    const git_diff_delta *delta, const git_diff_hunk *hunk,
    const git_diff_line *line, void *payload
) {
  DiffPrintPayload *diff_print_payload = payload;

  {
    FileSelectionPayload *file_selection = &diff_print_payload->file_selection;
    if (line->origin == 'F') {
      file_selection->last_file_status =
          file_status_char(file_selection->program->repo, delta->new_file.path);
    }
    if ((file_selection->only_untracked &&
         file_selection->last_file_status != '?') ||
        (!file_selection->only_untracked &&
         file_selection->last_file_status == '?')) {
      return 0;
    }
  }

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
      fprintf(
          stream, "@@ -%d,%d +%d,%d @@\n", hunk->old_start, hunk->old_lines,
          hunk->new_start, new_lines
      );
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
        fwrite(
            line->content, sizeof(*line->content), line->content_len, stream
        );
      }
    }
  }
  diff_print_payload->line_index++;
  return 0;
}

int main(int argc, char *argv[]) {
  atexit(ui_close);

  Options options = options_parse(argc, argv);
  Program program = {0};

  git_libgit2_init();
  e(git_repository_open_ext(&program.repo, ".", 0, NULL));

  git_diff_options diff_options = GIT_DIFF_OPTIONS_INIT;

  if (options.untracked_files) {
    diff_options.flags |= GIT_DIFF_INCLUDE_UNTRACKED |
                          GIT_DIFF_RECURSE_UNTRACKED_DIRS |
                          GIT_DIFF_SHOW_UNTRACKED_CONTENT;
  }
  e(git_diff_index_to_workdir(&program.diff, program.repo, NULL, &diff_options)
  );

  e(git_diff_print(
      program.diff, GIT_DIFF_FORMAT_PATCH, diff_count_number_of_lines, &program
  ));

  git_reference *head = NULL;
  e(git_repository_head(&head, program.repo));
  const char *branch = git_reference_shorthand(head);
  ui_init(
      branch, program.line_count, program.file_count,
      strcmp(branch, "main") == 0 || strcmp(branch, "master") == 0
  );

  {
    FileSelectionPayload context = {false, 0, &program};
    e(git_diff_print(
        program.diff, GIT_DIFF_FORMAT_PATCH, diff_build_ui, &context
    ));
    if (options.untracked_files) {
      context.only_untracked = true;
      e(git_diff_print(
          program.diff, GIT_DIFF_FORMAT_PATCH, diff_build_ui, &context
      ));
    }
  }

  const int ui_result_value = ui_loop();
  ui_close();
  switch (ui_result_value) {
  case 'P': {
    DiffPrintPayload context = {0, false, {false, 0, &program}, stdout};
    e(git_diff_print(program.diff, GIT_DIFF_FORMAT_PATCH, diff_print, &context)
    );
    if (options.untracked_files) {
      context.file_selection.only_untracked = true;
      e(git_diff_print(
          program.diff, GIT_DIFF_FORMAT_PATCH, diff_print, &context
      ));
    }
    break;
  }
  case 's':
  case 'c': {
    FILE *stage_command_stream =
        popen("git apply --cached --unidiff-zero -", "w");
    DiffPrintPayload context = {
        0, false, {false, 0, &program}, stage_command_stream};
    e(git_diff_print(program.diff, GIT_DIFF_FORMAT_PATCH, diff_print, &context)
    );
    if (options.untracked_files) {
      context.file_selection.only_untracked = true;
      e(git_diff_print(
          program.diff, GIT_DIFF_FORMAT_PATCH, diff_print, &context
      ));
    }
    fflush(stage_command_stream);
    const int return_code = pclose(stage_command_stream);
    if (return_code) {
      exit(return_code);
    }
    break;
  }
  }

  ui_free();

  git_reference_free(head);
  git_diff_free(program.diff);

  git_repository_free(program.repo);
  git_libgit2_shutdown();

  if ('c' == ui_result_value) {
    execlp("git", "git", "commit", NULL);
  }

  return 0;
}

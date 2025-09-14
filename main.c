#define _GNU_SOURCE

#include <git2.h>
#include <stdio.h>
#include <unistd.h>

#include "options.c"
#include "ui.c"

#define e(error)                                                               \
  if (error < 0) {                                                             \
    const git_error *e = git_error_last();                                     \
    printf("%d: Error %d/%d: %s\n", __LINE__, error, e->klass, e->message);    \
    exit(error);                                                               \
  }

typedef struct {
  Options options;
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
  (void)delta;
  (void)hunk;
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

bool ignore_diff_line(
    const char *file, const git_diff_line *line, FileSelectionPayload *context
) {
  if (line->origin == 'F') {
    context->last_file_status = file_status_char(context->program->repo, file);
  }
  return (context->only_untracked && context->last_file_status != '?') ||
         (!context->only_untracked && context->last_file_status == '?');
}

int diff_build_ui(
    const git_diff_delta *delta, const git_diff_hunk *hunk,
    const git_diff_line *line, void *payload
) {
  (void)hunk;
  FileSelectionPayload *context = payload;
  if (!ignore_diff_line(delta->new_file.path, line, payload)) {
    ui_add_line(line, delta, context->last_file_status);
  }
  return 0;
}

int count_new_lines_of_hunk(const UiLine *line, const git_diff_hunk *hunk) {
  const UiFile *file = line->file;
  const UiLine *end = file->lines + file->line_count;
  int new_lines = hunk->new_lines;
  for (line++; line < end; line++) {
    if (line->origin == 'H') {
      break;
    }
    if (!line->selected) {
      if (line->origin == '+') {
        new_lines--;
      } else if (line->origin == '-') {
        new_lines++;
      }
    }
  }
  return new_lines;
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
  DiffPrintPayload *context = payload;

  if (ignore_diff_line(delta->new_file.path, line, &context->file_selection)) {
    return 0;
  }

  FILE *stream = context->stream;
  const UiLine *ui_line = ui.lines + context->line_index;
  if (line->origin == 'H') {
    context->hunk_selected = !!ui_line->selected;
    if (ui_line->selected) {
      const int new_lines = count_new_lines_of_hunk(ui_line, hunk);
      fprintf(
          stream, "@@ -%d,%d +%d,%d @@\n", hunk->old_start, hunk->old_lines,
          hunk->new_start, new_lines
      );
    }
  } else if (line->origin == 'F') {
    if (context->file_selection.program->options.reverse &&
        delta->status == GIT_DELTA_ADDED &&
        ui_line->selected == selected_part) {
      fprintf(
          stream, "diff --git a/%s b/%s\n", delta->old_file.path,
          delta->new_file.path
      );
      fprintf(stream, "index 0000000..%06x\n", delta->new_file.mode);
      fprintf(stream, "--- a/%s\n", delta->old_file.path);
      fprintf(stream, "+++ b/%s\n", delta->new_file.path);
    } else if (ui_line->selected) {
      fwrite(line->content, sizeof(*line->content), line->content_len, stream);
    }
  } else if (context->hunk_selected) {
    if (ui_line->selected || line->origin == ' ') {
      fputc(line->origin, stream);
      fwrite(line->content, sizeof(*line->content), line->content_len, stream);
    } else if (line->origin == '-') {
      fputc(' ', stream);
      fwrite(line->content, sizeof(*line->content), line->content_len, stream);
    }
  }
  context->line_index++;
  return 0;
}

int main(int argc, char *argv[]) {
  atexit(ui_close);

  Options options = options_parse(argc, argv);
  Program program = {.options = options, 0};

  git_libgit2_init();
  e(git_repository_open_ext(&program.repo, ".", 0, NULL));

  if (chdir(git_repository_workdir(program.repo))) {
    perror("chdir");
    exit(1);
  }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
  git_diff_options diff_options = GIT_DIFF_OPTIONS_INIT;
#pragma GCC diagnostic pop
  /* diff_options.flags |= GIT_DIFF_INCLUDE_TYPECHANGE |
   * GIT_DIFF_SHOW_UNMODIFIED; */

  if (options.untracked_files) {
    diff_options.flags |= GIT_DIFF_INCLUDE_UNTRACKED |
                          GIT_DIFF_RECURSE_UNTRACKED_DIRS |
                          GIT_DIFF_SHOW_UNTRACKED_CONTENT;
  }
  if (options.reverse) {
    git_reference *head_ref = NULL;
    git_object *head_obj = NULL;
    git_tree *head_tree = NULL;

    e(git_repository_head(&head_ref, program.repo))
        e(git_reference_peel(&head_obj, head_ref, GIT_OBJ_COMMIT));
    e(git_commit_tree(&head_tree, (git_commit *)head_obj));
    e(git_diff_tree_to_index(
        &program.diff, program.repo, head_tree, NULL, &diff_options
    ));

    git_reference_free(head_ref);
    git_object_free(head_obj);
    git_tree_free(head_tree);
  } else {
    e(git_diff_index_to_workdir(
        &program.diff, program.repo, NULL, &diff_options
    ));
  }

  e(git_diff_print(
      program.diff, GIT_DIFF_FORMAT_PATCH, diff_count_number_of_lines, &program
  ));

  if (program.line_count == 0) {
    puts("No changes.");
    return 0;
  }

  git_reference *head = NULL;
  git_repository_head(&head, program.repo);
  const char *branch = head ? git_reference_shorthand(head) : "---";
  ui_init(
      branch, program.line_count, program.file_count,
      strcmp(branch, "main") == 0 || strcmp(branch, "master") == 0,
      options.reverse
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
    const char *stage_command;
    if (options.reverse) {
      stage_command = "git apply -R --cached --unidiff-zero -";
    } else {
      stage_command = "git apply --cached --unidiff-zero -";
    }
    FILE *stage_command_stream = popen(stage_command, "w");
    DiffPrintPayload context = {
        0, false, {false, 0, &program}, stage_command_stream
    };
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

  if (head) {
    git_reference_free(head);
  }
  git_diff_free(program.diff);

  git_repository_free(program.repo);
  git_libgit2_shutdown();

  if ('c' == ui_result_value) {
    execlp("git", "git", "commit", NULL);
  }

  return 0;
}

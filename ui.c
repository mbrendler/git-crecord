#include <git2.h>
#include <ncurses.h>
#include <string.h>

#include "lib.h"

typedef struct UiFile UiFile;

typedef enum {
  selected_not,
  selected_full,
  selected_part,
  selected_unknown,
} UiSelected;

#define ui_select_char(selected)                                               \
  (selected == selected_full ? 'X' : (selected == selected_part ? '~' : ' '))

typedef struct {
  UiSelected selected;
  bool highlighted;
  char origin;     // 'F', 'H', '+', '-', ' '
  unsigned y;      // y position of the line file->win
  unsigned height; // number of displayed lines
  UiFile *file;
} UiLine;

typedef struct UiFile {
  bool expanded;
  unsigned height;
  unsigned line_count;
  UiLine *lines;
  WINDOW *win;
} UiFile;

typedef enum {
  color_normal = 1,
  color_green,
  color_red,
  color_hl,
  color_status_bar,
  color_status_bar_warn,
} UiColor;

typedef struct {
  int scroll_offset;
  unsigned highlighted;
  UiColor status_bar_color;
  const char *title;
  uint64_t start_us;
  unsigned line_count;
  UiLine *lines;
  unsigned file_count;
  UiFile *files;
} Ui;

static Ui ui = {
    .scroll_offset = 0,
    .highlighted = 0,
    .status_bar_color = color_status_bar,
    .title = "",
    .start_us = 0,
    .line_count = 0,
    .lines = NULL,
    .file_count = 0,
    .files = NULL,
};

void ui_init_colors(void) {
  start_color();
  use_default_colors();
  init_pair(color_normal, -1, -1);
  init_pair(color_green, COLOR_GREEN, -1);
  init_pair(color_red, COLOR_RED, -1);
  init_pair(color_hl, COLOR_BLACK, COLOR_GREEN);
  init_pair(color_status_bar, COLOR_BLACK, COLOR_BLUE);
  init_pair(color_status_bar_warn, COLOR_BLACK, COLOR_RED);
}

void ui_init(const char *title, int line_count, int file_count, bool warn) {
  ui.title = title;
  ui.status_bar_color = warn ? color_status_bar_warn : color_status_bar;
  ui.start_us = micros();
  ui.lines = malloc(sizeof(*(ui.lines)) * line_count);
  ui.files = malloc(sizeof(*(ui.files)) * file_count);
  initscr();
  keypad(stdscr, TRUE);
  ui_init_colors();
  noecho();
}

void ui_close(void) {
  endwin();
  for (unsigned i = 0; i < ui.file_count; i++) {
    delwin(ui.files[i].win);
  }
}

void ui_free(void) {
  free(ui.lines);
  free(ui.files);
  ui = (Ui){
      .line_count = 0,
      .file_count = 0,
      .scroll_offset = 0,
      .highlighted = 0,
      .title = "",
      .start_us = 0,
      .lines = NULL,
      .files = NULL,
  };
}

#define ui_line_x_offset(line)                                                 \
  (line->origin == 'F' ? 0 : (line->origin == 'H' ? 3 : 6))

#define ui_line_color(line)                                                    \
  (line->origin == '+' ? color_green : (line->origin == '-' ? color_red : 0))

void ui_add_line(const git_diff_line *line, const git_diff_delta *delta,
                 char status) {
  unsigned height = 1;
  unsigned y = 0;
  UiLine *entry = &ui.lines[ui.line_count];
  ui.line_count++;
  UiFile *file = NULL;

  if ('F' == line->origin) {
    height = 3;
    file = &ui.files[ui.file_count];
    ui.file_count++;
    *file = (UiFile){
        .height = height + 1,
        .expanded = false,
        .lines = entry,
        .line_count = 1,
        .win = newpad(1, COLS),
    };
  } else {
    file = &ui.files[ui.file_count - 1];
    y = file->height - 1;
    file->line_count++;
    file->height += height;
  }
  *entry = (UiLine){
      .selected = line->origin == ' ' ? selected_not : selected_full,
      .highlighted = ui.line_count == 1,
      .y = y,
      .height = height,
      .origin = line->origin,
      .file = file,
  };

  // TODO: wrap lines
  wresize(file->win, file->height, COLS);
  const char *selected = entry->selected ? "[X]  " : "[ ]  ";
  mvwaddstr(file->win, y, ui_line_x_offset(line),
            line->origin == ' ' ? "     " : selected);
  if ('F' == line->origin) {
    waddch(file->win, status);
    waddch(file->win, ' ');
    waddstr(file->win, delta->new_file.path);
  } else if ('H' == line->origin) {
    waddnstr(file->win, line->content, line->content_len);
    mvwchgat(file->win, y, 0, -1, A_BOLD, 0, NULL);
  } else {
    waddch(file->win, line->origin);
    waddnstr(file->win, line->content, line->content_len);
    mvwchgat(file->win, y, ui_line_x_offset(line) + 4, -1, 0,
             ui_line_color(line), NULL);
  }
}

void ui_unhighlight(void) {
  const UiLine *line = &ui.lines[ui.highlighted];
  const int attr = line->origin == 'F' || line->origin == 'H' ? A_BOLD : 0;
  const int x_offset = ui_line_x_offset(line) + 4;
  const int color = ui_line_color(line);
  for (unsigned i = 0; i < line->height; i++) {
    mvwchgat(line->file->win, line->y + i, x_offset, -1, attr, color, NULL);
  }
}

void ui_highlight(void) {
  const UiLine *line = &ui.lines[ui.highlighted];
  const int attr = line->origin == 'F' || line->origin == 'H' ? A_BOLD : 0;
  const int x_offset = ui_line_x_offset(line) + 4;
  for (unsigned i = 0; i < line->height; i++) {
    mvwchgat(line->file->win, line->y + i, x_offset, -1, attr, color_hl, NULL);
  }
}

void ui_update_status_bar(void) {
  const int available = COLS - strlen(ui.title);
  if (available < 0) {
    return;
  }
  move(0, 0);
  clrtoeol();
  mvaddstr(0, 1, ui.title);
  if (available <= 0) {
    return;
  }
  char r_status[available + 1];
  const uint32_t duration = micros() - ui.start_us;
  snprintf(r_status, available, "%d/%d %uµs", ui.highlighted + 1, ui.line_count,
           duration);
  mvaddstr(0, COLS - strlen(r_status), r_status);
  mvchgat(0, 0, -1, A_BOLD, ui.status_bar_color, NULL);
}

static const int SCROLL_OFFSET = 3;
static const int STATUS_BAR_HEIGHT = 1;

/*
+---------------------+
|status_bar           | y = 0
|[ ] file             | y = 1           viewport_start = 0
|   [ ] hunk          |
|      [ ] line       |
|                     | y = LINES - 1   viewport_end
+---------------------+
*/
void ui_refresh(void) {
  const int viewport_start = STATUS_BAR_HEIGHT;
  const int viewport_end = LINES - 1;

  // recalculate scroll_offset
  {
    const UiLine *line = &ui.lines[ui.highlighted];
    const int screen_start = ui.scroll_offset;
    const int screen_end = ui.scroll_offset + viewport_end;
    int line_y = line->y;
    for (UiFile *file = ui.files; file < line->file; file++) {
      line_y += file->expanded ? file->height : 1;
    }
    if (line_y < screen_start + SCROLL_OFFSET) {
      ui.scroll_offset = MAX(line_y - SCROLL_OFFSET + viewport_start, 0);
    } else if (line_y > screen_end - 3 - SCROLL_OFFSET) {
      ui.scroll_offset = line_y - viewport_end + 3 + SCROLL_OFFSET;
    }
  }

  refresh();
  int y = -ui.scroll_offset + viewport_start;
  for (UiFile *file = ui.files; file < ui.files + ui.file_count; file++) {
    const int height = file->expanded ? file->height + 1 : 1;
    int end_y = y + height;
    if (end_y > viewport_end) {
      end_y = viewport_end;
    }
    if (end_y >= viewport_start) {
      const int top_y_on_screen = y >= viewport_start ? 0 : -y;
      const int top_y_of_content = MAX(y, viewport_start);
      prefresh(file->win, top_y_on_screen, 0, top_y_of_content, 0, end_y, COLS);
    }
    y += height;
    if (y > viewport_end) {
      break;
    }
  }
  if (y < LINES) {
    move(y, 0);
    clrtobot();
  }

  ui_update_status_bar();
}

void ui_highlight_next(void) {
  ui_unhighlight();
  const UiLine *line = &ui.lines[ui.highlighted] + 1;
  const UiLine *end = &ui.lines[ui.line_count];
  for (; line < end; line++) {
    if (!line->file->expanded && line->file->lines != line) {
      line = &line->file->lines[line->file->line_count - 1];
      continue;
    }
    if (' ' == line->origin) {
      continue;
    }
    ui.highlighted = line - ui.lines;
    break;
  }
  ui_highlight();
}

void ui_highlight_prev(unsigned line_index) {
  if (line_index == 0) {
    return;
  }
  ui_unhighlight();
  const UiLine *line = &ui.lines[line_index - 1];
  for (; line >= ui.lines; line--) {
    if (!line->file->expanded && line->file->lines != line) {
      line = line->file->lines + 1;
      continue;
    }
    if (' ' == line->origin) {
      continue;
    }
    ui.highlighted = line - ui.lines;
    ui_highlight();
    return;
  }
}

void ui_expand_file(void) {
  if (ui.lines[ui.highlighted].origin == 'F') {
    ui.lines[ui.highlighted].file->expanded = true;
  }
}

void ui_collaps_file(void) {
  if (ui.lines[ui.highlighted].origin == 'F') {
    ui.lines[ui.highlighted].file->expanded = false;
  }
}

void ui_update_file_and_hunk_selection_state(void) {
  const UiFile *file = ui.lines[ui.highlighted].file;
  UiSelected file_selected = selected_unknown;
  UiSelected hunk_selected = selected_unknown;
  for (UiLine *line = file->lines + file->line_count - 1; line > file->lines;
       line--) {
    switch (line->origin) {
    case 'H':
      line->selected = hunk_selected;
      mvwaddch(file->win, line->y, ui_line_x_offset(line) + 1,
               ui_select_char(hunk_selected));
      hunk_selected = selected_unknown;

      if (file_selected == selected_unknown) {
        file_selected = line->selected;
      } else if (file_selected != line->selected) {
        file_selected = selected_part;
      }
      break;
    case '+':
    case '-':
      if (hunk_selected == selected_unknown) {
        hunk_selected = line->selected;
      } else if (hunk_selected != line->selected) {
        hunk_selected = selected_part;
      }
      break;
    }
  }
  file->lines->selected = file_selected;
  mvwaddch(file->win, 0, 1, ui_select_char(file_selected));
}

void ui_select(void) {
  UiLine *line = &ui.lines[ui.highlighted];
  const UiSelected selected = !line->selected;
  const char select_char = ui_select_char(selected);
  const UiFile *file = line->file;

  if (line->origin == 'F') {
    const UiLine *end = &file->lines[file->line_count];
    for (; line < end; line++) {
      if (line->origin != ' ') {
        line->selected = selected;
        mvwaddch(file->win, line->y, ui_line_x_offset(line) + 1, select_char);
      }
    }
  } else if (line->origin == 'H') {
    const UiLine *end = &file->lines[file->line_count];
    for (line++; line < end && line->origin != 'H'; line++) {
      if (line->origin != ' ') {
        line->selected = selected;
        mvwaddch(line->file->win, line->y, ui_line_x_offset(line) + 1,
                 select_char);
      }
    }
    ui_update_file_and_hunk_selection_state();
  } else {
    line->selected = selected;
    mvwaddch(file->win, line->y, ui_line_x_offset(line) + 1, select_char);
    ui_update_file_and_hunk_selection_state();
  }
}

void ui_select_toggle_all(void) {
  const UiSelected selected = !ui.lines[ui.highlighted].selected;
  const char select_char = ui_select_char(selected);
  for (UiLine *line = ui.lines; line < ui.lines + ui.line_count; line++) {
    if (line->origin != ' ') {
      line->selected = selected;
      mvwaddch(line->file->win, line->y, ui_line_x_offset(line) + 1,
               select_char);
    }
  }
}

int ui_loop(void) {
  // post init
  {
    for (UiFile *file = ui.files; file < ui.files + ui.file_count; file++) {
      int lines = 0;
      int hunks = 0;
      for (UiLine *line = file->lines; line < file->lines + file->line_count;
           line++) {
        if (line->origin == 'H') {
          hunks++;
        } else if (line->origin == '+' || line->origin == '-') {
          lines++;
        }
      }
      mvwprintw(file->win, 1, 8, "%d hunks, %d lines", hunks, lines);
      mvwchgat(file->win, 0, 0, -1, A_BOLD, 0, NULL);
      mvwchgat(file->win, 1, 0, -1, A_BOLD, 0, NULL);
      mvwchgat(file->win, file->height - 1, 0, -1, A_UNDERLINE | A_BOLD, 0,
               NULL);
    }
  }

  ui_highlight();
  ui_refresh();

  int c = 0;
  while ((c = getch())) {
    ui.start_us = micros();
    switch (c) {
    // TODO: redraw on resize
    case KEY_UP:
    case 'k':
      ui_highlight_prev(ui.highlighted);
      break;
    case KEY_DOWN:
    case 'j':
      ui_highlight_next();
      break;
    case 'g':
      ui_unhighlight();
      ui.highlighted = 0;
      ui_highlight();
      break;
    case 'G':
      ui_highlight_prev(ui.line_count);
      break;
    case KEY_RIGHT:
    case 'l':
      ui_expand_file();
      break;
    case KEY_LEFT:
    case 'h':
      ui_collaps_file();
      break;
    case ' ':
      ui_select();
      break;
    case 'A':
      ui_select_toggle_all();
      break;
    case 'c':
    case 's':
    case 'P':
    case 'q':
      return c;
    }
    ui_refresh();
  }
  return c;
}

#include <git2.h>
#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

typedef struct UiFile UiFile;

typedef struct {
  bool selected;
  bool highlighted;
  char origin;
  unsigned y;
  unsigned height;
  UiFile *file;
} UiLine;

typedef struct UiFile {
  bool expanded;
  unsigned height;
  unsigned line_count;
  UiLine *lines;
  WINDOW *win;
} UiFile;

typedef struct {
  unsigned entry_count;
  unsigned file_count;
  unsigned scroll_offset;
  unsigned highlighted;
  const char *title;
  /* WINDOW *win; */
  UiLine *lines;
  UiFile *files;
} Ui;

static Ui ui = {
    .entry_count = 0,
    .file_count = 0,
    .scroll_offset = 0,
    .highlighted = 0,
    .title = "",
    .lines = NULL,
    .files = NULL,
    /* .win = NULL, */
};

typedef enum {
  color_normal = 1,
  color_green,
  color_red,
  color_hl,
  color_status_bar,
} UiColor;

void ui_init_colors(void) {
  start_color();
  use_default_colors();
  init_pair(color_normal, -1, -1);
  init_pair(color_green, COLOR_GREEN, -1);
  init_pair(color_red, COLOR_RED, -1);
  init_pair(color_hl, COLOR_BLACK, COLOR_GREEN);
  init_pair(color_status_bar, COLOR_BLACK, COLOR_BLUE);
}

void ui_init(const char *title, int line_count) {
  ui.title = title;
  /* ui.entry_count = line_count; */
  ui.lines = malloc(sizeof(*(ui.lines)) * line_count);
  ui.files = malloc(sizeof(*(ui.files)) * 10); // TODO
  /* ui.win = newpad(100, COLS); */
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
  free(ui.lines);
  free(ui.files);
  /* delwin(ui.win); */
  ui = (Ui){
      .entry_count = 0,
      .file_count = 0,
      .scroll_offset = 0,
      .highlighted = 0,
      .title = "",
      /* .win = NULL, */
      .lines = NULL,
      .files = NULL,
  };
}

#define ui_line_offset(line)                                                   \
  (line->origin == 'F' ? 0 : (line->origin == 'H' ? 3 : 6))

void ui_add_line(const git_diff_line *line) {
  unsigned height = 1;
  unsigned y = 0;
  UiLine *entry = &ui.lines[ui.entry_count];
  ui.entry_count++;
  UiFile *file = NULL;

  if ('F' == line->origin) {
    height = 4;
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
      .selected = false,
      .highlighted = ui.entry_count == 1,
      .y = y,
      .height = height,
      .origin = line->origin,
      .file = file,
  };

  // TODO: wrap lines
  wresize(file->win, file->height, COLS);
  const char *selected = entry->selected ? "[X]  " : "[ ]  ";
  mvwaddstr(file->win, file->height - height - 1, ui_line_offset(line),
            line->origin == ' ' ? "     " : selected);
  waddch(file->win, line->origin);
  waddnstr(file->win, line->content, line->content_len);
}

void ui_unhighlight(void) {
  UiLine *line = &ui.lines[ui.highlighted];
  mvwchgat(line->file->win, line->y, 0, -1, 0, 0, NULL);
}

void ui_highlight(void) {
  UiLine *line = &ui.lines[ui.highlighted];
  mvwchgat(line->file->win, line->y, 0, -1, 0, color_hl, NULL);
}

void ui_expand_file(void) {
  if (ui.lines[ui.highlighted].origin != 'F') {
    return;
  }
  ui.lines[ui.highlighted].file->expanded = true;
}

void ui_collaps_file(void) {
  if (ui.lines[ui.highlighted].origin != 'F') {
    return;
  }
  ui.lines[ui.highlighted].file->expanded = false;
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
  snprintf(r_status, available, "%d/%d ", ui.highlighted + 1, ui.entry_count);
  mvaddstr(0, COLS - strlen(r_status), r_status);
  mvchgat(0, 0, -1, A_BOLD, color_status_bar, NULL);
}

void ui_refresh(void) {
  ui_update_status_bar();
  // TODO: update scroll_offset
  ui_highlight();
  /* prefresh(ui.win, 0, 0, 1, 0, LINES - 1, COLS); */
  refresh();
  int y = ui.scroll_offset + 1;
  for (unsigned i = 0; i < ui.file_count; i++) {
    const UiFile *file = &ui.files[i];
    const int height = file->expanded ? file->height : 1;
    int end_y = y + height - 1;
    if (end_y >= LINES) {
      end_y = LINES - 1;
    }
    prefresh(file->win, 0, 0, y, 0, end_y, COLS);
    y += height;
    if (y >= LINES) {
      break;
    }
  }
  if (y < LINES) {
    move(y, 0);
    clrtobot();
  }
}

void ui_highlight_next(void) {
  ui_unhighlight();
  const UiLine *line = &ui.lines[ui.highlighted] + 1;
  const UiLine *end = &ui.lines[ui.entry_count];
  for (; line < end; line++) {
    if (!line->file->expanded && line->file->lines != line) {
      line = &line->file->lines[line->file->line_count - 1];
      continue;
    }
    if (' ' == line->origin) {
      continue;
    }
    ui.highlighted = line - ui.lines;
    return;
  }
}

void ui_highlight_prev(void) {
  ui_unhighlight();
  const UiLine *line = &ui.lines[ui.highlighted] - 1;
  const UiLine *begin = ui.lines;
  for (; line >= begin; line--) {
    if (!line->file->expanded && line->file->lines != line) {
      line = line->file->lines + 1;
      continue;
    }
    if (' ' == line->origin) {
      continue;
    }
    ui.highlighted = line - ui.lines;
    return;
  }
}

void ui_highlight_last(void) {
  ui_unhighlight();
  const UiLine *line = &ui.lines[ui.entry_count - 1];
  for (; line >= ui.lines; line--) {
    if (!line->file->expanded && line->file->lines != line) {
      line = line->file->lines + 1;
      continue;
    }
    if (' ' == line->origin) {
      continue;
    }
    ui.highlighted = line - ui.lines;
    return;
  }
}

void ui_select(void) {
  UiLine *line = &ui.lines[ui.highlighted];
  const bool selected = !line->selected;
  line->selected = selected;
  const char select_char = selected ? 'X' : ' ';
  mvwaddch(line->file->win, line->y, ui_line_offset(line) + 1, select_char);
  const UiFile *file = line->file;

  if (line->origin == 'F') {
    for (unsigned i = 0; i < file->line_count; i++) {
      UiLine *line = &file->lines[i];
      if (line->origin != ' ') {
        line->selected = selected;
        mvwaddch(file->win, line->y, ui_line_offset(line) + 1, select_char);
      }
    }
  } else if (line->origin == 'H') {
    UiLine *end = &file->lines[file->line_count];
    for (line++; line < end; line++) {
      if (line->origin == 'H') {
        break;
      }
      if (line->origin != ' ') {
        line->selected = selected;
        mvwaddch(line->file->win, line->y, ui_line_offset(line) + 1,
                 select_char);
      }
    }
    // TODO: update file line
  } else {
    // TODO: update hunk and file line
  }
}

int ui_loop(void) {
  int c;

  for (unsigned i = 0; i < ui.file_count; i++) {
    UiFile *file = &ui.files[i];
    mvwchgat(file->win, file->height - 1, 0, -1, A_UNDERLINE | A_BOLD, 0, NULL);
  }

  ui_refresh();
  while ((c = getch())) {
    switch (c) {
    // TODO: redraw on resize
    case KEY_UP:
    case 'k':
      ui_highlight_prev();
      break;
    case KEY_DOWN:
    case 'j':
      ui_highlight_next();
      break;
    case 'g':
      ui_unhighlight();
      ui.highlighted = 0;
      break;
    case 'G':
      ui_highlight_last();
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
    case 'q':
    case 'c':
    case 's':
      return c;
    }
    ui_refresh();
  }
  return c;
}

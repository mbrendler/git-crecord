#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  unsigned height;
  bool expanded;
  WINDOW *win;
} UiFile;

typedef struct {
  unsigned entry_count;
  unsigned highlighted;
  const char *title;
  unsigned file_count;
  UiFile *files;
} Ui;

static Ui ui = {
    .entry_count = 0,
    .highlighted = 0,
    .title = "",
    .file_count = 0,
    .files = NULL,
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

void ui_init(const char *title) {
  ui.title = title;
  initscr();
  keypad(stdscr, TRUE);
  ui_init_colors();
  noecho();
  move(1, 0);
}

void ui_close(void) {
  endwin();
  for (unsigned i = 0; i < ui.file_count; i++) {
    delwin(ui.files[i].win);
  }
  free(ui.files);
  ui = (Ui){
      .entry_count = 0,
      .highlighted = 0,
      .title = "",
      .file_count = 0,
      .files = NULL,
  };
}

void ui_add_file(const char *filename) {
  ui.file_count++;
  ui.files = realloc(ui.files, sizeof(UiFile) * ui.file_count);
  UiFile *file = &ui.files[ui.file_count - 1];
  const int height = 4;
  WINDOW *win = newpad(height, COLS);
  *file = (UiFile){
      .height = height,
      .expanded = false,
      .win = win,
  };

  int x, y;
  getmaxyx(win, y, x);
  mvwprintw(win, 0, 0, "[ ] %s (%d, %d)", filename, x, y);
  mvwaddstr(win, 1, 0, "       1 hunk(s), 6 line(s) changed TODO");
  mvwchgat(win, file->height - 1, 0, -1, A_UNDERLINE | A_BOLD, 0, NULL);
  ui.entry_count++;
}

/* void ui_add_entry(const char *entry) { */
/*   addstr(entry); */
/*   addch('\n'); */
/*   ui.entry_count++; */
/*   refresh(); */
/* } */

void ui_unhighlight(void) {
  mvwchgat(ui.files[ui.highlighted].win, 0, 0, -1, 0, 0, NULL);
}

void ui_highlight(void) {
  mvwchgat(ui.files[ui.highlighted].win, 0, 0, -1, 0, color_hl, NULL);
}

void ui_expand_file(void) {
  ui.files[ui.highlighted].expanded = true;
}

void ui_collaps_file(void) {
  ui.files[ui.highlighted].expanded = false;
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
  ui_highlight();
  refresh();
  int x = 1;
  for (unsigned i = 0; i < ui.file_count; i++) {
    UiFile *file = &ui.files[i];
    const int height = file->expanded ? file->height : 1;
    prefresh(file->win, 0, 0, x, 0, x + height - 1, COLS);
    x += height;
  }
  move(x, 0);
  clrtobot();
}

int ui_loop(void) {
  int c;
  ui_refresh();
  while ((c = getch())) {
    switch (c) {
    case KEY_UP:
    case 'k':
      ui_unhighlight();
      ui.highlighted = (ui.highlighted - 1) % ui.entry_count;
      break;
    case KEY_DOWN:
    case 'j':
      ui_unhighlight();
      ui.highlighted = (ui.highlighted + 1) % ui.entry_count;
      break;
    case KEY_RIGHT:
    case 'l':
      ui_expand_file();
      break;
    case KEY_LEFT:
    case 'h':
      ui_collaps_file();
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

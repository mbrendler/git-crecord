# git-crecord

Stage and commit git changes partially.

![Screenshot](/screenshot.jpg?raw=true)

## Build

Install dependencies:

```shell
$ apt install gcc libgit2-dev libncurses-dev   # Debian/Ubuntu
$ brew install libgit2                         # macOS
```

Build:

```shell
$ build.sh
```

## Usage

```shell
$ git crecord
$ git crecord --untracked-files  # show untracked files
$ git crecord --reverse          # unstage hunks
```

Key-bindings:

```
  q      - quit
  s      - stage selection and quit
  c      - commit selection and quit
  j / ↓  - down
  k / ↑  - up
  h / ←  - collapse fold
  l / →  - expand fold
  f      - toggle fold
  g      - go to first line
  G      - go to last line
  C-P    - up to previous hunk / file
  C-N    - down to next hunk / file
  SPACE  - toggle selection
  A      - toggle all selections
  ?      - display help
  R      - force redraw
```

## Run tests

```shell
$ apt install git
```

Tests:

```shell
$ ./system-test.sh
```

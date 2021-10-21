# git-crecord

Inspired by crecord mercurial extension, git-crecord is an easy way to
commit/stage git changes partially.

![Screenshot](/screenshot.jpg?raw=true)

## Installation

```shell
$ gem install git-crecord
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

## Configuration

```shell
# configure tab-width to four spaces, default is two spaces:
$ git config --global crecord.tabwidth 4
```

## Development

```shell
$ git clone https://github.com/mbrendler/git-crecord
$ cd git-crecord
$ bundle install
$ ln -s bin/git-crecord /usr/bin/git-crecord
```

Tests:
```shell
$ bundle exec rake
```

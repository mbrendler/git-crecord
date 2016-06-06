# git-crecord

Inspred by [crecord mercurial extension](https://bitbucket.org/edgimar/crecord/wiki/Home), git-crecord is an easy way for partially committing/staging of git changes.

## Install

 TODO

## Usage

```shell
$ git crecord
```

Key-bindings:
```
  q      - quit
  s      - stage selection and quit
  c      - commit selection and quit
  j / ↓  - down
  k / ↑  - up
  h / ←  - collapse hunk
  l / →  - expand
  f      - toggle fold
  g      - go to first line
  G      - go to last line
  C-P    - up to previous hunk / file
  C-N    - down to previous hunk / file
  SPACE  - toggle selection
  A      - toggle all selections
  ?      - this help window
  R      - force redraw
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
$ bundle exec rake test
$ bundle exec rake systemtest
```
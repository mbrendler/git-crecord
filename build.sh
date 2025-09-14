#! /bin/sh

export LIBRARY_PATH=/opt/homebrew/lib
export C_INCLUDE_PATH=/opt/homebrew/include

cc -g -std=c2x -Werror -Wall -Wextra -Wpedantic -O3 -o git-crecord \
  main.c \
  -lgit2 \
  -lncurses

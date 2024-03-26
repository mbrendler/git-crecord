#! /bin/sh

# export LIBGIT2=/opt/homebrew/opt/libgit2/lib/libgit2.a
export LIBRARY_PATH=/opt/homebrew/opt/libgit2/lib
export C_INCLUDE_PATH=/opt/homebrew/opt/libgit2/include

cc -g -std=c2x -Werror -Wall -Wpedantic -O3 -o git-crecord \
  main.c \
  -lgit2 \
  -lncurses


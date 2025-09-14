FROM debian:stable-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    gcc libgit2-dev libncurses-dev git \
  && rm -rf /var/lib/apt/lists/*

COPY . /code

WORKDIR /code

RUN ./build.sh
RUN ./system-test.sh

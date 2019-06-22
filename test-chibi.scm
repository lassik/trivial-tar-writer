#! /usr/bin/env chibi-scheme

(import (scheme base)
        (scheme write)
        (trivial-tar-writer))

(tar-write-file "hello/world.text" (string->utf8 "hello world"))

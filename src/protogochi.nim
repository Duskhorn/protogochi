import notcurses/ffi
import std/enumerate
import os

var 
  nc = newNotCurses(NcOptions())
  std = nc.stdplane


std.put_string("Welcome to yet another fucking test. I hope you're happy :3", 50, 80)
nc.render()

sleep 2000

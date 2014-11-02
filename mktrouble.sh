#!/bin/bash
# TODO
#   * use find?
#

for t in "DREW" "DOING" "DONE" "DEVEL" "DEBUG" "FIXME" "TODO" "FUTURE" "XXX"; do
    grep -rl $t * | grep -v mktrouble.sh | grep -v CVS | grep -v .svn | grep -v .git > trouble.$t
done

find trouble.* -empty -print0 | xargs -0 -Jy rm y

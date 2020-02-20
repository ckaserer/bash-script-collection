#!/bin/bash

function echo_stderr () { 
  >&2 echo "$@"
}
# readonly definition of a function throws an error if another function 
# with the same name is defined a second time
readonly -f echo_stderr
[ "$?" -eq "0" ] || return $?

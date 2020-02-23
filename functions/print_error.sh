#!/bin/bash

function print_error () { 
  >&2 echo "ERROR: $@"
}
# readonly definition of a function throws an error if another function 
# with the same name is defined a second time
readonly -f print_error
[ "$?" -eq "0" ] || return $?

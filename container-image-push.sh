#!/bin/bash

####################### 
# READ ONLY VARIABLES #
#######################

readonly PROG_NAME=`basename "$0"`
readonly SCRIPT_HOME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#################### 
# GLOBAL VARIABLES #
####################

FLAG_DRYRUN=false

########## 
# SOURCE #
##########

for functionFile in ${SCRIPT_HOME}/functions/*.sh; do 
  source ${functionFile}
done

##########
# SCRIPT #
##########

usage_message () {
  echo """
  ${PROG_NAME} is designed to be used as part of your CI/CD to push a docker image to dockerhub. 
      
  Usage:
    ${PROG_NAME} --image <DOCKER_IMAGE> --username <USERNAME> --password <PASSWORD> [OPT ..]
      
      required
        --image)             ... image name to push to registry
        --username)          ... docker username with push privileges
        --password)          ... docker password
      
      optional
        --git-branch)        ... if git-branch is not set to 'master' the script will not push the image to dockerhub
        --is-pull-request)   ... if is-pull-request is true, do nothing - allowed values ['true','false','0','1']. default: 'false'
        --allow-push-from)   ... regex for branches that are allowed to trigger a push to dockerhub. default: 'master'

        -d | --dryrun)       ... dryrun
        -h | --help)         ... help"""
}
readonly -f usage_message
[ "$?" -eq "0" ] || return $?

main () {
  # INITIAL VALUES
  local image=""
  local username=""
  local password=""

  local allow_push_from="master"
  local git_branch="master"
  local flag_is_pull_request=false

  # GETOPT
  local opts=`getopt -o dh --long dryrun,help,image:,username:,password:,git-branch:,is-pull-request:,allow-push-from: -- "$@"`
  if [ $? != 0 ]; then
    print_error "failed to fetch options via getopt"
    exit 1
  fi
  eval set -- "${opts}"
  while true ; do
    case "${1}" in
      --image) 
        image=${2}
        shift 2
        ;; 
      --username) 
        username=${2}
        shift 2
        ;; 
      --password) 
        password=${2}
        shift 2
        ;; 
      --git-branch) 
        git_branch=${2}
        shift 2
        ;; 
      --allow-push-from)
        allow_push_from=${2}
        shift 2
        ;; 
      --is-pull-request) 
        case ${2} in
          true | 0)    
            flag_is_pull_request=true;
            ;;
          false | 1)  
            flag_is_pull_request=false;
            ;;
          *) 
            print_error
            print_error "invalid parameter for --is-pull-request: \"${2}\""
            print_error "Allowed parameters are [0,1,true,false]\n"
            print_error
            usage_message
            exit 1
            ;;
        esac
        shift 2
        ;; 
      -d | --dryrun) 
        FLAG_DRYRUN=true
        shift
        ;; 
      -h | --help) 
        usage_message
        exit 0
        ;;
      *) 
        break
        ;;
    esac
  done
  
  ####
  # CHECK INPUT
  # check if all required options are given
  
  check_for_pull_request ${flag_is_pull_request}

  # if [ -z "$VAR" ]; This will return true if a variable is unset or set to the empty string ("").
  if [ -z "${image+x}" ] || [ -z "${username+x}" ] || [ -z "${password+x}" ]; then
      print_error
      print_error "please provide all required options"
      print_error "--image = ${image}"
      print_error "--username = ${username}"
      print_error "--password = (hidden)"
      print_error
      usage_message
      return 1
  fi
  
  ####
  # CORE LOGIC
  
  if cmp_regex ${git_branch} ${allow_push_from}; then
    docker_login ${username} ${password}
    execute "docker push ${image}"
  else
    print_info "branch '${git_branch}' did not meet the regex '${allow_push_from}'"
    print_info "no action taken"
  fi
}
 
main $@
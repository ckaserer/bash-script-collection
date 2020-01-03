#!/bin/bash

####################### 
# READ ONLY VARIABLES #
#######################

readonly PROGNAME=`basename "$0"`
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
  echo """Usage:
    $PROGNAME [OPT ..]
      required
        --docker-org)      ... target docker organization. This could be your username or a destinct organization
        --docker-repo)     ... target docker repository
        --docker-user)     ... docker username with push privileges
        --docker-pass)     ... docker password
      
      optional
        --git-branch)      ... if git-branch is not set to 'master' the script will not push the image to dockerhub
        --is-pull-request) ... if is-pull-request is true, do nothing - allowed values ['true','false','0','1']. default: 'false'

        -d | --dryrun)     ... dryrun
        -h | --help)       ... help"""
}
readonly -f usage_message
[ "$?" -eq "0" ] || return $?

main () {
  # INITIAL VALUES
  local docker_org=""
  local docker_repo=""
  local docker_user=""
  local docker_pass=""

  local git_branch="master"
  local flag_is_pull_request=false

  # GETOPT
  OPTS=`getopt -o dh --long dryrun,help,docker-org:,docker-repo:,docker-user:,docker-pass:,git-branch:,is-pull-request: -- "$@"`
  if [ $? != 0 ]; then
    echo_stderr "failed to fetch options via getopt"
    exit 1
  fi
  eval set -- "${OPTS}"
  while true ; do
    case "${1}" in
      --docker-org) 
        docker_org=${2}
        shift 2
        ;; 
      --docker-repo) 
        docker_repo=${2}
        shift 2
        ;; 
      --docker-user) 
        docker_user=${2}
        shift 2
        ;; 
      --docker-pass) 
        docker_pass=${2}
        shift 2
        ;; 
      --git-branch) 
        git_branch=${2}
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
            echo_stderr
            echo_stderr "invalid parameter for --is-pull-request: \"${2}\""
            echo_stderr "Allowed parameters are [0,1,true,false]\n"
            echo_stderr
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

  # if [ -z "$VAR" ]; This will return true if a variable is unset or set to the empty string ("").
  if [ -z "${docker_org}" ] || [ -z "${docker_repo}" ] || [ -z "${docker_user}" ] || [ -z "${docker_pass}" ]; then
      echo_stderr
      echo_stderr "please provide all required options"
      echo_stderr "--docker-org = ${docker_org}"
      echo_stderr "--docker-repo = ${docker_repo}"
      echo_stderr "--docker-user = ${docker_user}"
      echo_stderr "--docker-pass = (hidden)"
      echo_stderr
      usage_message
      return 1
  fi
 
  ####
  # CORE LOGIC
  
  if ${flag_is_pull_request}; then
    echo -e "Skipping - pull requests can not utilize encrypted variables.\nFor further information see: https://docs.travis-ci.com/user/pull-requests/#pull-requests-and-security-restrictions"
  else
    if [ "${git_branch}" == "master" ]; then
      execute "echo \"${docker_pass}\" | docker login -u \"${docker_user}\" --password-stdin" "Docker Login (hidden)"
      execute "docker push ${docker_org}/${docker_repo}"
    fi
  fi
}
 
main $@
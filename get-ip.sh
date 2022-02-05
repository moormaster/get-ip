#!/usr/bin/bash

# vi: ts=2:et

PARAM_IPV4=0
PARAM_IPV6=0
PARAM_IPV4_WEBCHECK_URL="http://checkip.dyndns.com/"
PARAM_IPV6_WEBCHECK_URL="http://checkipv6.dyndns.com/"
PARAM_VERBOSE=0

usage() {
  echo "$0 <-4 | --ipv4 | -6 | --ipv6> [-i <url>|--ipv4-webcheck-url <url>] [-j <url> | --ipv6-webcheck-url <url>] [-v  | --verbose]" 1>&2
  echo "  -4 | --ipv4" 1>&2
  echo "    query IPv4 address from ipv4 webcheck url" 1>&2
  echo "  -6 | --ipv6" 1>&2
  echo "    query IPv6 address from ipv6 webcheck url" 1>&2
  echo "  -i | --ipv4-webcheck-url" 1>&2
  echo "    URL to query ipv4 address from. Default: http://checkip.dyndns.com" 1>&2
  echo "  -j | --ipv6-webcheck-url" 1>&2
  echo "    URL to query ipv6 address from. Default: http://checkipv6.dyndns.com" 1>&2
  echo "  -v | --verbose" 1>&2
  echo "    verbose output"
}

log() {
  local verbosity="$1"
  local message="$2"

  [ "${verbosity}" -le ${PARAM_VERBOSE} ] && echo -e "${message}"
}

logerror() {
  local verbosity="$1"
  local message="$2"

  [ "${verbosity}" -le ${PARAM_VERBOSE} ] && echo -e "${message}" 1>&2
}

parse_arguments() {
  while [ $# -gt 0 ]
  do
    case $1 in
      -4 | --ipv4)
        PARAM_IPV4=1
        shift 1
        ;;

      -6 | --ipv6)
        PARAM_IPV6=1
        shift 1
        ;;

      -i | --ipv4-webcheck-url)
        if [ -z "$2" ]
        then
          logerror 0 "$1: Missing url parameter"
          return 1
        fi
        PARAM_IPV4_WEBCHECK_URL="$1"
        shift 2
        ;;

      -j | --ipv6-webcheck-url)
        if [ -z "$2" ]
        then
          logerror 0 "$1: Missing url parameter"
          return 1
        fi
        PARAM_IPV6_WEBCHECK_URL="$1"
        shift 2
        ;;

      -v | -verbose)
        PARAM_VERBOSE=1
        shift 1
        ;;

      *)
        logerror 0 "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  if [ "${PARAM_IPV4}" -eq 0 ] && [ "${PARAM_IPV6}" -eq 0 ]
  then
    logerror 0 "Either parameter -4 or -6 must be given!"
    return 1
  fi

  return 0
}

query-url() {
  local url="$1"
  local stdoutfile="$2"
  local stderrfile="$3"

  if ! which curl > /dev/null 2> /dev/null
  then
    logerror 0 "curl is not installed"
    return 1
  fi

  local ipv4
  logerror 1 "Executing: curl -s --stderr ${stderrfile} --output ${stdoutfile} ${url}"

  if ! curl -s --stderr ${stderrfile} --output ${stdoutfile} ${url}
  then
    logerror 0 "curl failed: $( cat ${stderrfile} )"
    return 1
  fi

  logerror 1 "curl response:\n$( cat ${stdoutfile} )"

  return 0
}

query-ipv4() {
  local stdoutfile stderrfile
  stdoutfile=$( mktemp )
  stderrfile=$( mktemp )

  logerror 1 "Prepared temporary file for stdout of curl: ${stdoutfile}"
  logerror 1 "Prepared temporary file for stderr curl: ${stderrfile}"

  local ipv4
  if ! query-url "${PARAM_IPV4_WEBCHECK_URL}" "${stdoutfile}" "${stderrfile}"
  then
    rm ${stdoutfile}
    rm ${stderrfile}
    return 1
  fi

  logerror 1 "parsing ipv4 from\n$( cat ${stdoutfile} )"

  ipv4=$( cat ${stdoutfile} | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' )

  logerror 1 "parsing result: ${ipv4}"

  if [ -z "${ipv4}" ]
  then
    logerror 0 "Failed to parse ipv4 from curl response:\n$( cat ${stdoutfile} )"
    rm ${stdoutfile}
    rm ${stderrfile}
    return 1
  fi

  log 0 "${ipv4}"

  rm ${stdoutfile}
  rm ${stderrfile}
  return 0
}

query-ipv6() {
  local stdoutfile stderrfile
  stdoutfile=$( mktemp )
  stderrfile=$( mktemp )

  logerror 1 "Prepared temporary file for stdout of curl: ${stdoutfile}"
  logerror 1 "Prepared temporary file for stderr curl: ${stderrfile}"

  local ipv6
  if ! query-url "${PARAM_IPV6_WEBCHECK_URL}" "${stdoutfile}" "${stderrfile}"
  then
    rm ${stdoutfile}
    rm ${stderrfile}
    return 1
  fi

  logerror 1 "parsing ipv6 from\n$( cat ${stdoutfile} )"

  ipv6=$( cat "${stdoutfile}" | grep -o '\([0-9a-fA-F]*:\)\+\([0-9a-fA-F]\+\|[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)' )

  logerror 1 "parsing result: ${ipv4}"

  if [ -z "${ipv6}" ]
  then
    logerror 0 "Failed to parse ipv6 from curl response:\n$( cat ${stdoutfile} )"
    rm ${stdoutfile}
    rm ${stderrfile}
    return 1
  fi

  log 0 "${ipv6}"

  rm ${stdoutfile}
  rm ${stderrfile}
  return 0
}

main() {
  logerror 1 "PARAM_IPV4=${PARAM_IPV4}"
  logerror 1 "PARAM_IPV6=${PARAM_IPV6}"
  logerror 1 "PARAM_IPV4_WEBCHECK_URL=${PARAM_IPV4_WEBCHECK_URL}"
  logerror 1 "PARAM_IPV6_WEBCHECK_URL=${PARAM_IPV6_WEBCHECK_URL}"
  logerror 1 "PARAM_VERBOSE=${PARAM_VERBOSE}"

  local ipv4 ipv6 output

  if [ "${PARAM_IPV4}" -eq 1 ]
  then
    ipv4="$( query-ipv4 )" || return 1
  fi

  if [ "${PARAM_IPV6}" -eq 1 ]
  then
    ipv6="$( query-ipv6 )" || return 1
  fi

  output="${ipv4}"

  if [ -n "${ipv6}" ]
  then
    if [ -n "${output}" ]
    then
      output="${output},${ipv6}"
    else
      output="${ipv6}"
    fi
  fi

  log 0 ${output}
}

if [ "${BASH_ARGV0}" == "${BASH_SOURCE}" ]
then
  if ! parse_arguments "$@"
  then
    usage
    exit 1
  fi

  main
fi

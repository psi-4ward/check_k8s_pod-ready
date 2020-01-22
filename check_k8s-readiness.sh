#!/usr/bin/env bash
# Kubernetes pod-readiness monitoring plugin
#
# Check if all pods for a given namespace/app pass the readiness probe
#
# https://github.com/psi-4ward/check_k8s_pod-ready
# Author: Christoph Wiechert
# License: MIT

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

print_help() {
  echo "Kubernetes pod-readiness monitoring plugin"
  echo "https://github.com/psi-4ward/check_k8s_pod-ready"
  echo
  echo "Usage: $0 <options>"
  echo "  -p <project>   K8s Namspace"
  echo "  -a <app>       AppName in Namespace"
  echo "  -e <endpoint>  IP or Host with Port of K8s API (ie 192.168.99.102:8443)"
  echo "  -t <token>     Auth-Token (oc sa get-token ...)"
  exit 0
}

# Read CLI Arguments
while [[ $# -ge 1 ]] ; do
  arg="$1"
  case $arg in
    -p)
      PROJECT="$2"
      shift
    ;;
    -a)
      APP="$2"
      shift
    ;;
    -e)
      ENDPOINT="$2"
      shift
    ;;
    -t)
      TOKEN="$2"
      shift
    ;;
    -h|--help)
      print_help
    ;;
  esac
  shift
done

# Some validation
if [ -z "$PROJECT" ]; then
  >&2 echo -e "ERROR: Project parameter is empty.\n\n"
  print_help
  exit $STATE_UNKOWN
fi
if [ -z "$APP" ]; then
  >&2 echo -e "ERROR: App parameter is empty.\n\n"
  print_help
  exit $STATE_UNKOWN
fi
if [ -z "$ENDPOINT" ]; then
  >&2 echo -e "ERROR: Endpoint parameter is empty.\n\n"
  print_help
  exit $STATE_UNKOWN
fi
if [ -z "$TOKEN" ]; then
  >&2 echo -e "ERROR: Token parameter is empty.\n\n"
  print_help
  exit $STATE_UNKOWN
fi


# Query K8s API
RES=$(curl --insecure -sSL --show-error --fail \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/json' \
    https://${ENDPOINT}/api/v1/namespaces/${NAMESPACE}/pods?labelSelector=app%3D${APP} 2>&1)

if [ "$?" != "0" ]; then
  >&2 echo "Request ERROR: $RES"
  exit $STATE_UNKNOWN
fi

if [ $(echo "$RES" | jq -M -r '.items | length') == 0 ]; then
  >&2 echo "ERROR: No pods found for $PROJECT/$APP."
  exit $STATE_UNKNOWN
fi

# Parse Response
POD_STATES=$(echo "$RES" | jq -M -r '.items[] | [.metadata.name,.status.containerStatuses[0].ready] | @tsv')

EXIT_CODE=$STATE_OK
LINE_NR=0
while IFS= read -r LINE; do
  POD_NAME=$(echo $LINE | cut -d' ' -f1)
  POD_READY=$(echo $LINE | cut -d' ' -f2)
  if [ "$POD_READY" != "true" ] ; then 
    echo -n "ERROR: $POD_NAME is "
    echo "$RES" | jq -M -r ".items[$LINE_NR].status.containerStatuses[0].state.waiting.reason"
    EXIT_CODE=$STATE_CRITICAL
  else
    echo $POD_NAME is READY
  fi
  LINE_NR=$((LINE_NR+1))
done <<< "$POD_STATES"

exit $EXIT_CODE

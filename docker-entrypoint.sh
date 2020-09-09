#!/usr/bin/env bash

set -euo pipefail

echo "Starting ... "

if [[ -z "${CUSTOMER_IP_ADDRESS_ANNOTATION+x}" ]]; then
    echo "Variable CUSTOMER_IP_ADDRESS_ANNOTATION is empty or not defined" >&2
    exit 1
fi

CUSTOMER_IP_ADDRESS_ANNOTATION_ESCAPED=$(sed 's/\./\\./g' <<< ${CUSTOMER_IP_ADDRESS_ANNOTATION})
NODE_IP=$(kubectl get nodes ${NODE_NAME} -o jsonpath="{ $.metadata.annotations.${CUSTOMER_IP_ADDRESS_ANNOTATION_ESCAPED} }")

if [[ -z "${NODE_IP}" ]]; then
    echo "Annotation [${CUSTOMER_IP_ADDRESS_ANNOTATION}] for node \"${NODE_NAME}\" is not defined ... " >&2
    exit 1
fi

if  ip -o a show lo | cut -d ' ' -f 7 | grep -q ${NODE_IP}/${NODE_IP_MASK}; then
  echo "${NODE_IP}/${NODE_IP_MASK} is already assigned to loopback ... skipping"
else
  set -x
  ip a add ${NODE_IP}/${NODE_IP_MASK} dev lo
  { set +x; } 2>/dev/null
fi

if iptables -C POSTROUTING -s ${POD_SUBNET} ! -d ${POD_SUBNET} -j SNAT --to-source ${NODE_IP} > /dev/null 2>&1; then
  echo "rule already present ... skipping"
else
  set -x
  iptables -t nat -I POSTROUTING 1 -s ${POD_SUBNET} ! -d ${POD_SUBNET} -j SNAT --to-source ${NODE_IP}
  { set +x; } 2>/dev/null
fi

echo "Done"

# suppress warnings
pause >/dev/null 2>&1

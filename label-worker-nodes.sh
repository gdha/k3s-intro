#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

for node in node2 node3
do
  kubectl label node $node kubernetes.io/role=node --overwrite
  kubectl label node $node node-role.kubernetes.io/node="" --overwrite
done

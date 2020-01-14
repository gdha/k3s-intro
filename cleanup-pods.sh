#!/bin/bash
# Remove all pods created during the demo, if present

echo "
	Cleaning up the demo pods
"

# remove the manifest, otherwise, it will be recreated automatically
rm -f /var/lib/rancher/k3s/server/manifests/hello.yaml 

kubectl get namespace | grep -q ^test && \
  kubectl delete namespace test

kubectl get pods -n default 2>/dev/null | grep -q ^hello && \
  kubectl delete pods -n default hello

kubectl get namespace | grep -q ^test && \
  kubectl delete namespace test

kubectl get pods -n default 2>/dev/null | grep -q ^nginx && \
  kubectl delete -f deploy/manifests/nginx2.yaml

kubectl get pods -n default 2>/dev/null | grep -q ^demo-sl-train && \
  kubectl delete pods -n default demo-sl-train

kubectl get pods -n mysql 2>/dev/null | grep ^svclb | awk '{print $1}' | while read id
do
  [[ ! -z "$id" ]] && kubectl delete pods -n mysql $id
done

kubectl get svc -n mysql 2>/dev/null | grep -q ^mysql-svc && \
  kubectl delete service -n mysql mysql-svc

kubectl get svc -n mysql 2>/dev/null | grep -q ^local-database-mysql && \
  kubectl delete service -n mysql local-database-mysql

kubectl get pods -n mysql 2>/dev/null | grep ^local-database-mysql | awk '{print $1}' | while read id
do 
  [[ ! -z "$id" ]] && kubectl delete pods -n mysql $id
done

helm ls --all local-database >/dev/null 2>&1 && \
  helm del --purge local-database

kubectl get namespace | grep -q ^mysql && \
  kubectl delete namespace mysql

# Remove the port-forwarding of mysql
PID=$(ps -ef| grep 'kubectl port-forward svc/local-database-mysql' | grep -v grep | awk '{print $2}')
[[ ! -z "$PID" ]] && kill -9 $PID

# finally show what is still running:
kubectl get all -A

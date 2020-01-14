#!/bin/bash
# Script: k3s-demo.sh
# Author: Gratien Dhaese <gratien.dhaese@gmail.com>

# FUNCTIONS
###########

function banner() {
echo "
         #####
 #    # #     #   ####           #####   ######  #    #   ####
 #   #        #  #               #    #  #       ##  ##  #    #
 ####    #####    ####           #    #  #####   # ## #  #    #
 #  #         #       #          #    #  #       #    #  #    #
 #   #  #     #  #    #          #    #  #       #    #  #    #
 #    #  #####    ####           #####   ######  #    #   ####
 
 $(bold $(green by Gratien Dhaese '<gratien.dhaese@gmail.com>'))

 $(bold https://github.com/gdha/k3s-intro)

 License: Apache License, Version 2.0
"
}

function pause() {
   printf "Press any key to continue" ; read dummy
}

function ansi() {
     case $(uname -s) in
        Linux)  echo -e "\e[${1}m${*:2}\e[0m" ;;
        Darwin) echo -e "\033[${1}m${*:2}\033[0m" ;;
             *) echo "$2" ;;
     esac
}

function bold() {
    ansi 1 "$@";
}

function green() {
     ansi 32 "$@";
}

function runcmd() {
  echo
  echo "$( bold "$1" )"
  echo "$( green $2 )"
  eval $2
  echo
  pause
}

##############
## MAIN     ##
##############

clear
banner
pause

# Show the 'sl' train made by https://github.com/gdha/sl_train
# while telling something about myself
runcmd "Playing with k3s brings me back to mid 80s when I started playing with unix" "kubectl run -i --tty demo-sl-train --image=gdha/sl_train --restart=Never -- sh -il /train"

clear

# Remove the sl_train pod again to have a clean sheet for the real demo
kubectl delete pods demo-sl-train >/dev/null 2>&1

banner
pause

runcmd "Add KUBECONFIG to .bashrc" "grep KUBECONFIG $HOME/.bashrc"

runcmd "Show the k3s nodes" "kubectl get nodes"

runcmd "Show the k3s nodes with option wide" "kubectl get nodes -o wide"

runcmd "Show the capacity of all our nodes as a stream of JSON objects" "kubectl get nodes -o json | jq \".items[] | {name:.metadata.name} + .status.capacity\""

runcmd "Show all the availbale namespaces" "kubectl get namespaces"

runcmd "Show the pods running in all namespaces" "kubectl get pods -A"

runcmd "Show all info about our cluster" "kubectl get all -A"

runcmd "Show list chart repositories" "helm repo list"

runcmd "Showing current installed helm charts" "helm list"

runcmd "Local k3s manifests" "ls /var/lib/rancher/k3s/server/manifests/"

runcmd "Copy the hello.yaml into manifests directory" "cp deploy/manifests/hello.yaml /var/lib/rancher/k3s/server/manifests/hello.yaml"

runcmd "Is container \"hello\" running?" "kubectl get pods | grep hello"

echo
echo "It will take a while before hello pod is visible"
pause

runcmd "Create a new namespace \"test\"" "kubectl apply -f  deploy/manifests/test-ns.yaml"

runcmd "Check if namespace \"test\" exist" "kubectl get namespace"

runcmd "Start 4 busybox pods (replicas=4)" "kubectl create -f deploy/manifests/busybox-ns.yaml"

runcmd "Verify where the busybox pods are running" "kubectl get pods -n test -o wide"

runcmd "Delete the 4 busybox pods again" "kubectl delete -f deploy/manifests/busybox-ns.yaml"

runcmd "Verify if the busybox pods are deleted" "kubectl get pods -n test -o wide"

runcmd "Deploy a simple nginx" "kubectl apply -f deploy/manifests/nginx2.yaml"

NGINX_POD="$( kubectl get pods | grep ^nginx | awk '{print $1}' )"
NGINX_NODE="$( kubectl get pods -o wide	| grep ^nginx | awk '{print $7}' )"
runcmd "Is the \"nginx\" pod running?" "kubectl get pods $NGINX_POD -o wide"

#runcmd "Start kubectl proxy to expose the nginx pod" "kubectl proxy &"

#echo "In another window run \"ssh -L 8001:localhost:8001 root@node1\""
#pause

echo "In a web browser copy/paste: http://$NGINX_NODE.box:31000/"
pause

rundcmd "Delete the nginx pod again" "kubectl delete -f deploy/manifests/nginx2.yaml"

runcmd "Is container \"hello\" already running now?" "kubectl get pods | grep hello"

runcmd "Deploy a mysql pod via helm" "helm install --name local-database --namespace mysql -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/mysql.yaml stable/mysql"

runcmd "Check if mysql pod is (already) running in namespace \"mysql\"" "kubectl get pods -n mysql"

# Before doing the port forwarding we must be sure that the pod is running!
rc=1
while (( $rc != 0 ))
do
  kubectl get pods -n mysql | grep ^local-database-mysql | grep -qi running
  rc=$?
  sleep 3
done

runcmd "Port forwarding localhost:3306 to connect to mysql database" "kubectl port-forward svc/local-database-mysql 3306 -n mysql &"

runcmd "Expose port 3306 to external IP" "kubectl expose deployment --name=mysql-svc local-database-mysql --type=LoadBalancer -n mysql"

runcmd "Show the services of mysql" "kubectl get services -n mysql"

MYSQL_POD="$(kubectl get pods -n mysql | grep ^local | awk '{print $1}')"
runcmd "On which worker node is the database running?" "kubectl get pods -n mysql $MYSQL_POD -o wide"

export MYSQL_HOST="$(kubectl describe pods -n mysql $MYSQL_POD | grep -i ^node: | cut -d/ -f2)"
export MYSQL_PORT=3306
export MYSQL_ROOT_PASSWORD=r00tpassw0rd

echo "Connecting to database on $MYSQL_HOST"
runcmd "Type \"exit;\" to exit from database" "mysql -h $MYSQL_HOST -P$MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD"

echo "
Connect to mysql database via host system (mysql-client must be installed).
Copy/paste the following on another terminal window (e.g. Linux or OS/x host) :
-----------------------------------------------------------------------------
mysql -h $MYSQL_HOST -P$MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD
-----------------------------------------------------------------------------
Type \"exit;\" to exit from database"
pause



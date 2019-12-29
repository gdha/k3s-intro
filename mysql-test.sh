#!/bin/bash
# Script is based on article:
# https://medium.com/@marcovillarreal_40011/cheap-and-local-kubernetes-playground-with-k3s-helm-5a0e2a110de9

echo "Installing the mysql-client package"
apt-get install mysql-client -y

echo "Installing mysql pod via helm in namespace mysql"
helm install --name local-database --namespace mysql -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/mysql.yaml stable/mysql

echo "Check if mysql pod is running in namespace mysql"
kubectl get pods -n mysql

echo "Port forwarding localhost:3306 to connect to mysql database"
kubectl port-forward svc/local-database-mysql 3306 -n mysql &

echo "Define some required variables before we can connect to database"
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3306
export MYSQL_ROOT_PASSWORD=r00tpassw0rd

echo "Connecting to database"
mysql -h $MYSQL_HOST -P$MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD


#!/bin/bash
# Script is based on article:
# https://medium.com/@marcovillarreal_40011/cheap-and-local-kubernetes-playground-with-k3s-helm-5a0e2a110de9

echo "Installing the mysql-client package"
apt-get install mysql-client -y

echo "Installing mysql pod via helm in namespace mysql - will run command:"
echo "helm install --name local-database --namespace mysql -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/mysql.yaml stable/mysql"
printf "Press any key to continue" ; read dummy
helm install --name local-database --namespace mysql -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/mysql.yaml stable/mysql

echo
echo "Check if mysql pod is (already) running in namespace \"mysql\""
kubectl get pods -n mysql
echo
echo "Wait a few seconds (10)"
sleep 10
kubectl get pods -n mysql
printf "Press any key to continue" ; read dummy

echo "Port forwarding localhost:3306 to connect to mysql database"
kubectl port-forward svc/local-database-mysql 3306 -n mysql &

echo "Expose port 3306 to external IP"
kubectl expose deployment --name=mysql-svc local-database-mysql --type=LoadBalancer -n mysql

echo "Show the services of mysql"
kubectl get services -n mysql
printf "Press any key to continue" ; read dummy

echo "On which worker node is the database running?"
MYSQL_POD="$(kubectl get pods -n mysql | grep ^local | awk '{print $1}')"
kubectl get pods -n mysql $MYSQL_POD -o wide
printf "Press any key to continue" ; read dummy

echo "Define some required variables before we can connect to database"
export MYSQL_HOST="$(kubectl describe pods -n mysql $MYSQL_POD | grep -i ^node: | cut -d/ -f2)"
export MYSQL_PORT=3306
export MYSQL_ROOT_PASSWORD=r00tpassw0rd

echo "Connecting to database on $MYSQL_HOST"
echo "Type \"exit;\" to exit from database"
mysql -h $MYSQL_HOST -P$MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD

echo
echo "Connect to mysql database via host system (mysql command must be installed)."
echo "Copy/paste the following on another terminal window (e.g. Linux or OS/x host) :"
echo "-----------------------------------------------------------------------------"
echo "mysql -h $MYSQL_HOST -P$MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD"
echo "-----------------------------------------------------------------------------"
echo "Type \"exit;\" to exit from database"

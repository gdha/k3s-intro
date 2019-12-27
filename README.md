

## Start an Ubuntu pod
````
kubectl run -i --tty ubuntu --image=ubuntu:16.04 --restart=Never -- bash -il
````

## Start the Rancher Server with docker (outside the k3s cluster)

````
docker run -d --restart=unless-stopped \
-p 80:80 -p 443:443 \
rancher/rancher:latest
````

Login via https://localhost/ as admin


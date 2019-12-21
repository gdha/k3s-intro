
## Start the Rancher Server with docker

````
docker run -d --restart=unless-stopped \
-p 80:80 -p 443:443 \
rancher/rancher:latest
````

Login via https://localhost/ as admin


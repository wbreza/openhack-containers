# Docker Tips

## Get List of running containers
```bash
docker container ls
```

# Setup SQL container
Follow steps outlined in [SQL container tutorial](https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver15&pivots=cs1-bash)

## Run the container
```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=<password>" \
   -p 1433:1433 --name ohsql \
   -d mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
```

## Connect to SQL running in container
Using locally installed `sqlcmd` tool run the following:
```bash
sqlcmd -S <ipaddress>,1433 -U <username> -P "<password>"
```
> To get the local IP address run `ipconfig` command

## Create new Database
```sql
>1 CREATE DATABASE mydrivingDB
>2 GO
```

## Load data into the db using the following command
```bash
docker run -e SQLFQDN=<ipaddress> -e SQLUSER=<username> -e SQLPASS="<password>" -e SQLDB=mydrivingDB openhack/data-load:v1
```

# Setup Azure Container Registry
1. Create a new Azure Container registry instance

Created `wabrezohcontainerregistry` with admin mode enabled.

## Login to the container registry
```bash
az.cmd acr login --name wabrezohcontainerregistry
```

# Setup Points of Interest API (POI)
Setup for the POI (Points of Interest container)

## Create the container
Copy `Dockerfile_3` into the `poi` src folder
Build the container with the name `poi` from the docker file
```bash
docker build -t poi .
```

## Tag & Push the container
Tag the container and associate with your remote container registry
```bash
docker tag poi wabrezohcontainerregistry.azurecr.io/poi
docker push wabrezohcontainerregistry.azurecr.io/poi
```

## Run the container
Run the container with an IP port mapping from 8081->80
```bash
docker run -d -p 8081:80 --name poi-api wabrezohcontainerregistry.azurecr.io/poi 
```

## Confirm container is running
Access the [health check](http://localhost:8081/api/poi/healthcheck) in your browser

# Setup User Profile API (Node)
Copy `Dockerfile_2` into the `userprofile` src folder
Build the container with the name `userprofile` from the docker file
```bash
docker build -t userprofile .
```
## Tag & Push the container
Tag the container and associate with your remote container registry
```bash
docker tag userprofile wabrezohcontainerregistry.azurecr.io/userprofile
docker push wabrezohcontainerregistry.azurecr.io/userprofile
```

## Run the container
Run the container with an IP port mapping from 8082->80
```bash
docker run -d -p 8082:80 --name userprofile-api wabrezohcontainerregistry.azurecr.io/userprofile
```

## Confirm container is running
Access the [health check](http://localhost:8082/api/user/healthcheck) in your browser

# Setup Trip API
Setup for the Trips API (GO application)
Copy `Dockerfile_4` into the `trips` src folder
Build the container with the name `trips` from the docker file
```bash
docker build -t trips .
```

## Tag & Push the container
Tag the container and associate with your remote container registry
```bash
docker tag trips wabrezohcontainerregistry.azurecr.io/trips
docker push wabrezohcontainerregistry.azurecr.io/trips
```

## Run the container
Run the container with an IP port mapping from 8083->80
```bash
docker run -d -p 8083:80 --name trips-api wabrezohcontainerregistry.azurecr.io/trips
```

## Confirm container is running
Access the [health check](http://localhost:8083/api/trips/healthcheck) in your browser

# Setup Trip Viewer App
Setup for the Trips API (GO application)
Copy `Dockerfile_1` into the `tripviewer` src folder
Build the container with the name `tripviewer` from the docker file
```bash
docker build -t tripviewer .
```

Update the API_ENDPOINT variables to point to container endpoints

## Tag & Push the container
Tag the container and associate with your remote container registry
```bash
docker tag tripviewer wabrezohcontainerregistry.azurecr.io/tripviewer
docker push wabrezohcontainerregistry.azurecr.io/tripviewer
```

## Run the container
Run the container with an IP port mapping from 8080->80
```bash
docker run -d -p 8080:80 --name tripviewer-ui wabrezohcontainerregistry.azurecr.io/tripviewer
```

## Confirm container is running
Access the [health check](http://localhost:8080) in your browser

# Kubernetes with AKS

## Creating cluster
- Create cluster using Azure portal or Azure CLI

### Configure local kubectl to access AKS cluster
```bash
az aks get-credentials --resource-group wabrez-openhack --name wabrez-openhack-aks
```

### Configure AKS cluster to access ACR (Azure Container Registry)
```bash
az aks update -n wabrez-openhack-aks -g wabrez-openhack --attach-acr wabrezohcontainerregistry
```

### Configure Kubernetes Dashboard
If using RBAC you need to enable access
```bash
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
```

To launch the dashboard run the following:
```bash
az aks browse --resource-group wabrez-openhack --name wabrez-openhack-aks
```

### Deployment Script
A full [deployment script](./scripts/aks.sh) has been created that does the following:
1. Configures kubectl CLI
1. Configures AKS access to ACR
1. Installs NGINX ingress controller
1. Creates `api-dev` namespace
1. Deploys secrets for DB access
1. Deploys application components
1. Deploys NGINX ingress

### Create your Kubernetes deployment manifests
- [POI API](./manifests/poi.yml)
- [Trips API](./manifests/trips.yml)
- [User API](./manifests/userprofile.yml)
- [TripViewer UI](./manifests/tripviewer.yml)

### Create secrets
```bash
# Create secrets
kubectl create secret generic db-credentials \
    --from-file=../secrets/db-username \
    --from-file=../secrets/db-password
```

### Create Deployment
Each service requires a seperate deployment manifest
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: poi
spec:
  selector:
    matchLabels:
      app: poi
  template:
    metadata:
      labels:
        app: poi
    spec:
      containers:
        - name: poi
          image: wabrezohcontainerregistry.azurecr.io/poi
          env:
            - name: SQL_SERVER
              value: wabrez-openhack-sql.database.windows.net
            - name: SQL_DBNAME
              value: myDrivingDB
            - name: SQL_USER
              valueFrom: # Example of pulling secrets defined above
                secretKeyRef:
                  name: db-credentials
                  key: db-username
            - name: SQL_PASSWORD
              valueFrom: # Example of pulling secrets defined above
                secretKeyRef:
                  name: db-credentials
                  key: db-password
          resources:
            limits:
              memory: "128Mi"
              cpu: "500m"
          ports:
            - containerPort: 80
```

### Create Service
Each service requires a service to be exposed for internal cluster communication
```yaml
apiVersion: v1
kind: Service
metadata:
  name: poi
spec:
  selector:
    app: poi
  ports:
    - port: 80
```

### Configure NGINX for ingress
Follow [NGINX tutorial](https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md) to install NGINX into your cluster

#### Get your ingress IP address
You need the external public IP address that will resolve from your DNS entry.
In this example we will use `http://tripviewer.com` which has been linked via local [HOSTS](file:///C:/Windows/System32/drivers/etc/hosts) file.
```bash
kubectl get service nginx-ingress --namespace nginx-ingress
```

See [ingress.yml](./manifests/ingress.yml) for full configuration

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tripviewer-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  backend: # This is the default backend for any routes that don't match the rules below
    serviceName: tripviewer
    servicePort: 80
  rules:
    - host: tripviewer.com # Note: Map this domain in your local HOSTS file to your AKS cluster ingress IP
      http:
        paths:
          - path: /api/poi
            backend:
              serviceName: poi
              servicePort: 80
          - path: /api/trips
            backend:
              serviceName: trips
              servicePort: 80
          - path: /api/user
            backend:
              serviceName: userprofile
              servicePort: 80

```
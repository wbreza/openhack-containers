#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

resourceGroup=$1
clusterName=$2
registryName=$3
init=${4:-false}

if [ "$init" = true ]; then
    echo "Configuring AKS cluster..."
    # Sets up kubectl configuration for AKS cluster
    az.cmd aks get-credentials --resource-group $resourceGroup --name $clusterName

    # Provides access for AKS cluster to access ACR
    az.cmd aks update -n $clusterName -g $resourceGroup --attach-acr $registryName

    kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
fi

# NGINX Requirements
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/common/ns-and-sa.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/common/default-server-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/common/nginx-config.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/common/custom-resource-definitions.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/rbac/rbac.yaml
# You can either use a deployment or a daemon set for NGINX
#kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/deployment/nginx-ingress.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/daemon-set/nginx-ingress.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/service/loadbalancer.yaml

# Create Namespace
kubectl apply -f ../manifests/namespace.yml

kubectl config set-context api-dev --namespace=api-dev \
  --cluster=wabrez-openhack-aks \
  --user=clusterUser_wabrez-openhack_wabrez-openhack-aks

kubectl config use-context api-dev

# Create secrets
kubectl create secret generic db-credentials \
    --from-file=../secrets/db-username \
    --from-file=../secrets/db-password

# Deploy services & pods
kubectl apply -f ../manifests/poi.yml
kubectl apply -f ../manifests/trips.yml
kubectl apply -f ../manifests/userprofile.yml
kubectl apply -f ../manifests/tripviewer.yml

# Create Ingress
kubectl apply -f ../manifests/ingress.yml

# kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
# az aks browse --resource-group $resourceGroup --name $clusterName
#!/bin/bash

# Set variables
rgname="b8duna"
aksname="AKSClusterDuna"
rgloc="francecentral"
redusr="devuser"
redpass="password_redis_154"
apitoken="2fbAa8tMWHBUnNwFi5EhuRgp"
certvers="v1.10.1"

# Create resource group
echo "Creating resource group..."
az group create --location $rgloc --name $rgname
echo "Resource group created."

# Create AKS cluster
echo "Creating AKS cluster..."
az aks create -g $rgname -n $aksname --enable-managed-identity --node-count 2 --enable-addons monitoring --enable-msi-auth-for-monitoring --generate-ssh-keys
echo "AKS cluster created."

# Get AKS cluster credentials
echo "Getting AKS cluster credentials..."
az aks get-credentials --resource-group $rgname --name $aksname
echo "AKS cluster credentials retrieved."

# Create Redis database secret
echo "Creating Redis database secret..."
kubectl create secret generic redis-secret-duna --from-literal=username=$redusr --from-literal=password=$redpass
echo "Redis database secret created."

# Add Jetstack Helm repository
echo "Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
echo "Jetstack Helm repository added."

# Install cert-manager with custom DNS settings
echo "Installing cert-manager..."
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --version v1.10.1 --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
echo "Cert-manager installed."

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
echo "NGINX Ingress Controller installed."

# Create Gandi API token secret
echo "Creating Gandi API token secret..."
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken
echo "Gandi API token secret created."

# Install cert-manager-webhook-gandi Helm chart
echo "Installing cert-manager-webhook-gandi Helm chart..."
helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager --set features.apiPriorityAndFairness=true --set logLevel=6 --generate-name
echo "cert-manager-webhook-gandi Helm chart installed."

# # Recover the webhook number from the cert-manager namespace
# kubectl get secrets -n cert-manager

# # Create role and rolebinding for accessing secrets
# echo "Creating role and rolebinding for accessing secrets..."
# kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets
# kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-1665665029
# echo "Role and rolebinding created."

# Create Prod & Fab namespaces
echo "Creating Prod & Fab namaspaces for QAL & Public deploy"
kubectl create namespace prod
kubectl create namespace fab
echo "Namespaces created"
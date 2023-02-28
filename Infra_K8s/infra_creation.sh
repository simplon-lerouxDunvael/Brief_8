#!/bin/bash

# Set variables
rgname="b8duna"
aksname="AKSClusterDuna"
rgloc="francecentral"
redusrqua="devuserqua"
redpassqua="password_redis_154"
redusrprod="devuserprod"
redpassprod="password_redis_265"
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

# Create Prod & Qua namespaces
echo "Creating Prod & Qua namespaces for QAL & Public deploy"
kubectl create namespace prod
kubectl create namespace qua
echo "Namespaces created"

# Create Redis database secret
echo "Creating Redis database secret for namespace qua..."
kubectl create secret generic redis-secret-duna --from-literal=username=$redusrqua --from-literal=password=$redpassqua -n qua
echo "Redis database secret created."
echo "Creating Redis database secret for namespace prod..."
kubectl create secret generic redis-secret-duna --from-literal=username=$redusrprod --from-literal=password=$redpassprod -n prod
echo "Redis database secret created."

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
helm install my-release nginx-stable/nginx-ingress
helm repo update
helm install nginx-qua nginx-stable/nginx-ingress --create-namespace --namespace qua --debug --set-controller.ingressClass="nginx-qua"
helm install nginx-prod nginx-stable/nginx-ingress --create-namespace --namespace prod --debug --set-controller.ingressClass="nginx-prod"
echo "NGINX Ingress Controller installed."

# Add Jetstack Helm repository
echo "Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
echo "Jetstack Helm repository added."

# # Install cert-manager with custom DNS settings
# echo "Installing cert-manager..."
# helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --version v1.10.1 --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
# echo "Cert-manager installed."

# # Create Gandi API token secret
# echo "Creating Gandi API token secret..."
# kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken
# # kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n prod
# echo "Gandi API token secret created."

# # Install cert-manager-webhook-gandi Helm chart
# echo "Installing cert-manager-webhook-gandi Helm chart..."
# helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager --set features.apiPriorityAndFairness=true --set logLevel=6 --generate-name
# echo "cert-manager-webhook-gandi Helm chart installed."

# # Recover the webhook number from the cert-manager namespace
# kubectl get secrets -n cert-manager

# # Create role and rolebinding for accessing secrets
# echo "Creating role and rolebinding for accessing secrets..."
# kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets
# kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-1665665029
# echo "Role and rolebinding created."


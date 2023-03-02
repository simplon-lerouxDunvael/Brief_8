<div style='text-align: justify;'>

<div id='top'/>

### Summary

###### [00 - Daily Scrum](#Scrum)

###### [01 - Kubernetes, AKS and Azure Pipelines doc reading](#Doc)

###### [02 - Architecture Topology](#Topology)

###### [03 - Resource List](#Resources)

###### [04 - Creation of a resource group](#RG)

###### [05 - Creation of a storage account (standard GRS)](#Storacc)

###### [06 - Creation of the AKS Cluster (with SSH keys generated)](#AKS)

###### [07 - Connecting the AKS Cluster and Azure](#Connecting)

###### [08 - Creation of the redis secret](#RedSecret)

###### [09 - Connecting to Azure DevOps Pipelines](#DevOps)

###### [10 - Creation of a test pipeline](#Pipeline)

###### [11 - Checks and tests](#Checks)

###### [12 - Error messages](#Error)

###### [13 - Trying to find a solution](#Solution)

###### [14 - Updating the voting app on the script](#Updating)

###### [15 - Remove the PV](#PV)

###### [16 - Delete everything and start again](#Again)

###### [17 - Add Ingress](#Ingress)

###### [18 - Install Cert-manager and Jetstack (for gandi)](#Cert-manager)

###### [19 - Creation of a Gandi secret](#Gsecret)

###### [20 - Install cert-manager webhook for gandi](#Webhook)

###### [21 - Creation of secret role and binding for webhook](#Binding)

###### [22 - Check the certificate](#Certificate)

###### [23 - Scheduling](#Scheduling)

###### [24 - Pipeline debugging](#Debugging)

###### [25 - How to get a certificate Summary](#Summary)

###### [26 - Executive summary](#ExecSummary)

###### [27 - Technical Architecture Document of deployed infrastructure](#DAT)

###### [28 - Check consumption](#Consumption)

###### [29 - Usefull Commands](#UsefullCommands)

<div id='Scrum'/>  

### **Scrum quotidien**

Scrum Master = Me, myself and I
Daily personnal reactions with reports and designations of first tasks for the day.

Frequent meeting with other coworkers to study solutions to encountered problems together.

[scrums](https://github.com/simplon-lerouxDunvael/Brief_7/blob/main/Plans_et_demarches/Scrum.md)

[&#8679;](#top)

<div id='Docs'/>  

#### **Kubernetes, AKS and Azure Pipelines doc reading**

Researches and reading of documentations to determine the needed prerequisites, functionnalities and softwares to complete the different tasks of Brief 8.

[&#8679;](#top)   

<div id='RG'/>  

### **Creation of a resource group**

I tried to create a resource group with a lock with a Bicep script I created. When I tried to deploy it, I had an error message telling me that I did not have the rights to deploy this script on Simplon's subscription.

![cant_deploy_bicep2sub](https://user-images.githubusercontent.com/108001918/221535360-df4fdccf-f457-435c-b581-9bfca9be9582.png)

So, I decided to do it via a script .sh.

[&#8679;](#top)

<div id='Storacc'/>  

### **Creation of a forked branch in GitHub**

As required in the brief, I forked Alfred's [azure-vote](https://github.com/simplon-alfred/azure-voting-app-redis) repos and renamed it as [Forked_azVotingApp_b8duna](https://github.com/simplon-lerouxDunvael/Forked_azVotingApp_b8duna) to avoid confusion.

![forked_branch](https://user-images.githubusercontent.com/108001918/221544580-67de67d0-c302-4a69-a55f-f1fedfb8d8a0.png)


[&#8679;](#top)

<div id='AKS'/>  

### **Creation of the AKS Cluster (with SSH keys generated)**

As Kubernetes is totally capable of handling it by itself and more reliably than human hand (with the right settings), I did not create a storage Account, PV creations and bindings.

I created my AKS cluster :

```bash
az aks create -g b8duna -n AKSClusterDuna --enable-managed-identity --node-count 2 --enable-addons monitoring --enable-msi-auth-for-monitoring  --generate-ssh-keys
```

[&#8679;](#top)

<div id='Connecting'/>  

### **Connecting the AKS Cluster and Azure**

Then I connected my AKS cluster to Azure.

```bash
az aks get-credentials --resource-group b8duna --name AKSClusterDuna
```

[&#8679;](#top)

<div id='RedSecret'/>  

### **Issues**

I deployed the azure voting app correctly but had issues once again with ingress and the TLS.
As Quentin, Luna and I, all had the same problems, we realized several tests while streaming our screens.

We tried and discussed our results and failures and finally came to terms.

We found that we needed to :

* create the two namespaces after connecting the AKS cluster to Azure
* create a redis secret for each namespace
* create a helm repository and add nginx to it
* install nginx in each namespace (qua and prod)
* leave some time to nginx to initialize and gets its IP address
* extract the external ip address of the nginx (still in load balancer)
* create a dns record A with nginx external ip address (one for each environment)
* create and add a Hetstack Helm repository to then install cert-manager in the cert-manager namespace
* install cert-manager webhook gandi in the cert-manager namespace
* deploy the voting app in each namespace
* deploy ingress version 1 in each namespace
* deploy let's encrypt issuer configuration files in each namespace
* create a gandi-credentials secret for each namespace (with the dns API token)
* deploy the certificate TLS for each namespace
* finally deploy ingress version 2 in each namespace

After deploying every resource in this order, we could all connect to the voting app from the https urls we chose (for both namespaces).

After all these steps, we decided (with Luna) to create a script that would deploy everything directly without having to redo the steps manually every time our resource groups get destroyed.

[&#8679;](#top)

<div id='DevOps'/>  

### **Connecting to Azure DevOps Pipelines**

First I went to Azure DevOps, created a project and clicked on Pipelines : <https://dev.azure.com/dlerouxext/b8duna> 

Then, I had to configure my organization and project's [visibility](https://learn.microsoft.com/en-us/azure/devops/organizations/projects/make-project-public?view=azure-devops). I went to the settings and turned on the visibility to public.

Since the last update of Kubernetes, the connection to Azure can't be made with the service connections.  
Therefore, I had to create a kubeconfig file that recovers several connections informations.

```Bash
az aks get-credentials --resource-group $rgname --name $aksname -f kubeconfig.yaml
```

Then I had to download it and place it directly in my Git repository (downloading it from azure terminal does not push it into Git):

```Bash
download kubeconfig.yaml
```

Once downloaded, I just had to put the code into the Kubernetes service connection (choosing autoConfig params) to be able to use my pipeline and Kubernetes services.

Then I created a Docker Hub registry in order to be able to build and push the Docker Image with my Pipeline. This way, the Docker image version would be updated when I excecuted the auto_maj.sh script and I could configure my pipeline to deploy Docker image the latest version into the qua and prod environments.

[&#8679;](#top)

<div id='Ingress'/>  

### **Deployment of Ingress**

Once I deployed redis and the azure voting app and checked that my pods were running properly I decided to install Ingress to be able to access to the voting app from an url http I chose (and that i would later link to my dns record).

First I installed everything that was necessary for ingress with the following command :

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
```

Then I created three different versions of Ingress.

* ingress_step1.yaml file  : the TLS parts, the host and the TLS annotations are commented. I applied it with ```kubectl apply -f ingress_step1.yaml``` and checked it with ```kubectl get ingress```.

![first_ingress_working](https://user-images.githubusercontent.com/108001918/221797099-15cb98e4-40ef-4fa2-b95b-b41ffc3f1d12.png)

After this step, ingress had an IP address. Then I created a "A" DNS record with the ingress IP address. I checked ingress and it now displayed with : smoothie.simplon-duna.space.

* ingress_step2.yaml file  : i added the dns to the host part. I applied it with ```kubectl apply -f ingress_step1.yaml``` and checked it with ```kubectl get ingress```.
* ingress_step3.yaml file  : the TLS parts and the TLS annotations are decommented and the host has its dns name added. I applied it with ```kubectl apply -f ingress_step1.yaml``` and checked it with ```kubectl get ingress```.

Finally I connected to the Voting app using smoothie.simplon-duna.space and it worked.

[&#8679;](#top)






[&#8679;](#top)

<div id='UsefullCommands'/>  

### **USEFULL COMMANDS**

### **To create an alias for a command on azure CLi**

alias [WhatWeWant]="[WhatIsChanged]"  

*Example :*  

```bash
alias k="kubectl"
```

[&#8679;](#top)

### **To deploy resources with yaml file**

kubectl apply -f [name-of-the-yaml-file]

*Example :*  

```bash
kubectl apply -f azure-vote.yaml
```

[&#8679;](#top)

### **To check resources**

```bash
kubectl get nodes
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get events
kubectl get secrets
kubectl get logs
```

*To keep verifying the resources add --watch at the end of the command :*

*Example :*

```bash
kubectl get services --watch
```

*To check the resources according to their namespace, add --namespace after the command and the namespace's name :*

*Example :*

```bash
kubectl get services --namespace [namespace's-name]
```

[&#8679;](#top)

### **To describe resources**

```bash
kubectl describe nodes
kubectl describe pods
kubectl describe services # or svc
kubectl describe deployment # or deploy
kubectl describe events
kubectl describe secrets
kubectl describe logs
```

*To specify which resource needs to be described just put the resource ID at the end of the command.*

*Example :*

```bash
kubectl describe svc redis-service
```

*To access to all the logs from all containers :*

```bash
kubectl logs podname --all-containers
```

*To access to the logs from a specific container :*

```bash
kubectl logs podname -c [container's-name]
```

*To list all events from a specific pod :*

```bash
kubectl get events --field-selector [involvedObject].name=[podsname]
```

[&#8679;](#top)

### **To delete resources**

```bash
kubectl delete deploy --all
kubectl delete svc --all
kubectl delete pvc --all
kubectl delete pv --all
az group delete --name [resourceGroupName] --yes --no-wait
```

[&#8679;](#top)

### **To create a repository Helm and install Jetstack**

*To create the repository and install Jetstack :*

```bash
helm repo add jetstack https://charts.jetstack.io
```

*To check the repository created and Jetstack version :*

```bash
helm search repo jetstack
```

[&#8679;](#top)

### **To create a role for Gandi's secret and bind it to the webhook**

*To create the role :*

```bash
kubectl create role [role-name] --verb=[Authorised-actions] --resource=[Authorised-resource]
```

*Example :*  

```bash
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets
```

*To bind it :*  

```bash
kubectl create rolebinding --role=[role-name] [role-name] --serviceaccount=[group]:[group-item]
```

*Example :*  

```bash
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-1665665029
```

[&#8679;](#top)

### **To check TLS certificate in request order**

```bash
kubectl get certificate
kubectl get certificaterequest
kubectl get order
kubectl get challenge
```

[&#8679;](#top)

### **To describe TLS certificate in request order**

```bash
kubectl describe certificate
kubectl describe certificaterequest
kubectl describe order
kubectl describe challenge
```

[&#8679;](#top)

### **Get the IP address to point the DNS to nginx**

```bash
kubectl get ingress
```

[&#8679;](#top)

### **Activate the autoscaler on an existing cluster**

```bash
az aks update --resource-group b6duna --name AKSClusterd2 --enable-cluster-autoscaler --min-count 1 --max-count 8
```

[&#8679;](#top)

### **To check the auto scaling creation**

```bash
get HorizontalPodAutoscaler
```

*Example of how the results will display :*  

```bash
horizontalpodautoscaler.autoscaling/scaling-voteapp created
```

[&#8679;](#top)

### **To check Webhook configuration**

```bash
kubectl get ValidatingWebhookConfiguration -A
```

[&#8679;](#top)

### **Delete Webhook configuration for a role**

```bash
kubectl delete -A ValidatingWebhookConfiguration [rolename]  
```

*Example :*  

```bash
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

[&#8679;](#top)

</div>

<div style='text-align: justify;'>

<div id='top'/>

### Summary

###### [00 - Daily Scrum](#Scrum)

###### [01 - Kubernetes, AKS and Azure Pipelines doc reading](#Doc)

###### [02 - Creation of a resource group](#RG)

###### [03 - Creation of a forked branch in GitHub](#branch)

###### [04 - Voting-app and Ingress deployment in two namespaces](#deployments)

###### [05 - Connecting to Azure DevOps Pipelines](#DevOps)

###### [06 - Pipeline creation](#PipeCreation)

###### [07 - Usefull Commands](#UsefullCommands)

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

<div id='branch'/>  

### **Creation of a forked branch in GitHub**

As required in the brief, I forked Alfred's [azure-vote](https://github.com/simplon-alfred/azure-voting-app-redis) repos.
As it was not possible to change the repository's visibility to private, I created a new Github repository with all the files from Alfred's repository so it could be used with Azure DevOps Pipelines.
I named it as [azVotingApp_b8duna](https://github.com/simplon-lerouxDunvael/azVotingApp_b8duna) to avoid confusion.

[&#8679;](#top)

<div id='deployments'/>  

### **Voting-app and Ingress deployment in two namespaces**

I deployed the azure voting app correctly but had issues once again with ingress and the TLS.
As Quentin, Luna and I, all had the same problems, we realized several tests while streaming our screens.

We tried and discussed our results and failures and finally came to terms.

We found that we needed to do things in a specific order so everything would run smoothly :

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

Here is a little explanation for the two different versions of Ingress.

* ingress_step1.yaml file  : the TLS parts and the TLS annotations are commented. I applied it with ```kubectl apply -f ingress_qua1.yaml```, ```kubectl apply -f ingress_prod1.yaml``` and checked it with ```kubectl get svc --all-namespaces``` to recover the external Ip address of the two Ingress.

I created two "A" DNS records with the ingress IP addresses (one for each namespace). Then i checked the ingress and they displayed with : smoothie-qua.simplon-duna.space and smoothie-prod.simplon-duna.space.

* ingress_step2.yaml file  : the TLS parts and the TLS annotations are decommented and the host has its dns name added. . I applied it with ```kubectl apply -f ingress_qua1.yaml```, ```kubectl apply -f ingress_prod1.yaml``` and checked it with ```kubectl get ingress```.

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

Then I had to download it and place it directly in my Git repository (downloading it from azure terminal does not push it into Git) :

```Bash
download kubeconfig.yaml
```

Once downloaded, I just had to put the code into the Kubernetes service connection (choosing autoConfig params) to be able to use my pipeline and Kubernetes services.

Then I created a Docker Hub registry in order to be able to build and push the Docker Image with my Pipeline. This way, the Docker image version would be updated when I excecuted the auto_maj.sh script and I could configure my pipeline to deploy Docker image the latest version into the qua and prod environments.

[&#8679;](#top)

<div id='PipeCreation'/>  

### **Pipeline creation**

The pipeline is constructed in a specific order :

* First I declared the variables that would be used several times
* Then I created a job to Build and Push the Docker Image into my Docker repository previously created
* Once the docker image was created, I deployed it (in a canary way) to the qua namespace and checked that the voting app responded well with a curl (deployment.yaml)
* Then as it worked, I deployed it (also in a canary way) to the prod namespace and checked that the voting app responded well with a curl too (deployment-canary.yaml)
* Then I used a bash script to check the replicas created (2 for prod, 1 for qua). This way, I knew that in the namespace prod, there were one voting app with the old version and one with the new version. The cluster IP would manage the users between the pods.
* Then I promoted the new version to all the pods in the prod namespace (deployment.yaml)
* As the checks were successful, I deleted the canary deployment from the prod namespace (deployment-canary.yaml)

As the pipeline was working correctly, I ran the auto_maj.sh script to check if the pipeline would automatically run. It did run properly.

Finally I created the update procedure document.

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

### **Get the IP address to point the DNS to nginx in the two namespaces**

```bash
kubectl get svc --all-namespaces
```

[&#8679;](#top)

</div>

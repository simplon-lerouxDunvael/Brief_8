# Update procedure Brief 8

In order to update the Voting App version via the Azure DevOps Pipeline, please follow these steps :

1) Open a bash terminal
2) Clone the github repository [azVotingApp_b8duna](https://github.com/simplon-lerouxDunvael/azVotingApp_b8duna)
3) In the bash terminal, go into the folder Infra_K8s (with `cd` or `pushd`)
4) Excecute the auto_maj.sh file (in the folder Infra_K8s) by typing :  

```Bash
bash auto_maj.sh
```

  or

 ```Bash
./auto_maj.sh
```

5) Once auto_maj.sh is deployed, the Pipeline will automatically run and deploy to the qua and prod environments
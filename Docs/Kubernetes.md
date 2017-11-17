## Kubernetes

#### Required Tools
- [Docker](https://docs.docker.com/engine/installation/)
- [Helm](https://docs.helm.sh/using_helm/#quickstart-guide)

#### Required IBM Cloud Tools
- [IBM Cloud CLI](https://console.bluemix.net/docs/cli/reference/bluemix_cli/get_started.html#getting-started)

#### Install IBM CLoud PLugins
- [IBM Cloud Container Service CLI](https://console.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install)
- [IBM Cloud Container Registry](https://console.bluemix.net/docs/services/Registry/registry_setup_cli_namespace.html#registry_setup_cli_namespace)
- [IBM Cloud Dev Plugin](https://console.bluemix.net/docs/cloudnative/dev_cli.html#developercli)

```
/// Used for creating containers
bx plugin install container-service -r Bluemix

/// Used for storing and sharing docker images
bx plugin install container-registry -r Bluemix

/// Deployment
bx plugin install dev

```

#### Step-By-Step Guide
1. Login following the prompts
```
bx login
```

2. Create a cluster
```
bx cs cluster-create --name BluePic-Cluster
```
More information on creating a cluster can be found [here](https://console.bluemix.net/docs/containers/cs_cluster.html#cs_cluster)

2. Export the Kube Config environment variable after executing the below
```
bx cs cluster-config BluePic-Cluster
```
 ** NOTE: When the download of the configuration files is finished, a command is displayed that you can use to set the path to the local Kubernetes configuration file as an environment variable. **

 Example for OS X:

 ```
 export KUBECONFIG=/Users/<user_name>/.bluemix/plugins/container-service/clusters/<cluster_name>/kube-config-prod-dal10-<cluster_name>.yml
 ```

3. Deploy your application and services (Make sure your cluster is finished deploying [Ready])

  ```
  sh ./Cloud-Scripts/deploy.sh cluster
  ```

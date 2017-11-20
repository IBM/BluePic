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

#### Quick Setup
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

3. Setup your Kube Environment and instantiate IBM Cloud services (Make sure your cluster is finished deploying [Ready])

  ```
  sh ./Cloud-Scripts/Deployment/kubernetes_setup.sh
  ```

4. Bind Services. In order to allow some services to instantiate fully, please wait 1-2 minutes before binding.

  ```
  sh ./Cloud-Scripts/Deployment/bind_services.sh
  ```

  In the event a service fails to bind because it has not instantiated fully, you should manually try again by executing the below command with the <service_name_here> field replaced with the service name.

  `bx cs cluster-service-bind BluePic-Cluster default <service_name_here>`

4. Build and Deploy Application

  ```
  sh ./Cloud-Scripts/Deployment/kubernetes_deploy.sh
  ```

5. After populating your database, you may view the application using the ip address and port provided in the output of step 4.

#### Troubleshooting Build Script
- When Binding Services...
  - Error: "The secret name is already in use.  Select a different name or remove the existing secret"

    When a service is bound to the cluster, it uses a secret to store the service credentials. In order to bind a new service instance you should remove the old binds.

    GUI:

    Execute `kubectl proxy` and navigate to `http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/secret?namespace=default` and delete all of the BluePic service secret bindings.

    Command line:

    Please run `bx cs cluster-service-bind "BluePic-Cluster" default <service_name>` using the failed service's name

    For further details on binding services to Kubernetes clusters, refer to the [Kubernetes clusters documentation] (https://console.bluemix.net/docs/containers/cs_apps.html#cs_appson) on IBM Cloud.
  - Error: "This IBM cloud service does not support the Cloud Foundry service keys API and cannot be added to your Cluster"

    This error message is likely occurring because the service instance has not fully instantiated. Please wait a few minutes and then try manually binding the service instance again.

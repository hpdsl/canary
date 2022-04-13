# canary

The current version of this project is tested on baremetal and in serverless environment using Apache OpenWhisk. The underlying operating system in all deployment environment is Ubuntu 18.04 LTS, and the deployment is orchestrated with Kubernetes with up to 8 nodes.

In order to use the provided scripts, please ensure you have root access to the machine and have cloned this repository into the `home` directory.

```
$ sudo su
$ cd $HOME
$ git clone https://github.com/hpdsl/canary.git
```

The configuration of a Kubernetes cluster for this project requires the following software packages:

* Docker
* Helm
* Kubernetes
* OpenWhisk
* MongoDB for database query workloads.


Install all requirements and build the serverless environment.

Run this command only on the master node of the Kubernetes cluster, not on the worker nodes.

```
$ make install
```

next, label the master node as core:

```
$ kubectl label nodes <MASTER_NODE_NAME> openwhisk-role=core
```

In case, the node's name is unknown, run ```kubectl get nodes```.
Ensure that the master node has passwordless ssh connection to the worker nodes.

Next, log into each worker node and run the following commands to configure and join the cluster.

```
$ git clone https://github.com/hpdsl/canary.git
$ sudo $HOME/canary/deploy/worker.sh
```
You will be prompted to reply some questions:
```
Enter Master's Public IP: <cluster IP>
Enter cluster's auth token: <cluster token>
Enter cluster's discovery token hash: <discovery hash>
```

The answer to these questions is available on the master node.

* **cluster IP** is obtained from `kubectl cluster-info`.
* **cluster token** is obtained from `kubeadm token list`. If there is no token, run `kubeadm token create`.
* **discovery token hash** is obtained from `openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`.

Return to the master node to label each of the worker nodes as invoker:

```
$ kubectl label nodes <WORKER_NODE_NAME> openwhisk-role=invoker
```
Finally, replace `<cluster IP>` in the folder `$HOME/canary/deploy/mycluster.yaml` by the ip address from the command `kubectl cluster-info`, and run the following command to deploy OpenWhisk in the Kubernetes cluster:

```
$ sudo $HOME/canary/deploy/deploy.sh
```
Once the setup completes, source the .bashrc file to start interacting with the framework.

```
$ source ~/.bashrc
```

### Execution

For our evaluation, we built a docker runtime image with workload dependencies and Openwhisk packages such as:

* Deep Learning Training: `hpdsl/canary:dltrain`
* Data Mining with Spark: `hpdsl/canary:sparkdiversity`
* Database query: `hpdsl/canary:dbquery`

In order to execute our evaluation workloads with *Canary*, run the following command.

```
$ canary <job> -m <model> -d <dataset> -b <batch> -e <epoch> -t <type>
```
For example `canary dl resnet50 mnist -b 64 -e 50 -t std` will train the ResNet50 model with the MNIST dataset over 50 epochs using a batch size of 64 in a standalone execution. The alternate type is "batch" to denote batch jobs.

You can also run the following command to see the description and available options for the parameters.

```
$ canary -h
```

The data query workload requires a database to query from. In our experiments, we used MongoDB as database and use PostgreSQL to query data. Download our dataset from YELP database at the following URL `k`. Next, extract and copy to the running docker container with the following commands

```
docker exec canary-db mkdir /tmp/canary
docker cp <each json file> canary-db
```

Next, the database query workload can be deployed by running `canary query -t std`

#!/usr/bin/env bash

# Deploying OpenWhisk
cd $HOME
git clone https://github.com/apache/openwhisk-deploy-kube.git

# Basic modificaition to the cluster deployment
echo "Changing the memory limit..."
sed -ri 's/^(\s*)(max: "512m").*/\1max: "12228m"/' $HOME/openwhisk-deploy-kube/helm/openwhisk/values.yaml
sed -ri 's/^(\s*)(userMemory: "2048m").*/\1userMemory: "1536000m"/' $HOME/openwhisk-deploy-kube/helm/openwhisk/values.yaml

echo "Changing the time limit to 20 minutes..."
sed -ri 's/^(\s*)(max: "5m").*/\1max: "15m"/' $HOME/openwhisk-deploy-kube/helm/openwhisk/values.yaml

echo "Changing the concurrency to 10..."
sed -ri 's/^(\s*)(max: 1).*/\1max: 10/' $HOME/openwhisk-deploy-kube/helm/openwhisk/values.yaml
sed -ri 's/^(\s*)(std: 1).*/\1std: 4/' $HOME/openwhisk-deploy-kube/helm/openwhisk/values.yaml

echo "Setting API version to 1..."
sed -ri 's/^(\s*)(apiVersion: *).*/\1apiVersion: v1/' $HOME/openwhisk-deploy-kube/helm/openwhisk/Chart.yaml

cd openwhisk-deploy-kube
kubectl create namespace openwhisk
echo "Initializing the deployment..."
helm init --stable-repo-url https://charts.helm.sh/stable
echo "Waiting for the tiller pod to be ready. Sleeping for 4 minutes"
sleep 4m
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

echo "Deploying the Kubernetes cluster for Openwhisk..."
helm install $HOME/openwhisk-deploy-kube/helm/openwhisk --namespace=openwhisk --name=owdev -f $HOME/dl-serverless/conf/kubernetes/mycluster.yaml
echo "Waiting for the OpenWhisk core components to be ready. Sleeping for 6 minutes"
sleep 6m
kubectl run canary-db --image=mongo --restart=Never -n openwhisk

# WSK authentication configuration
printf "Enter Master\'s Public IP: "
read masterIP
wsk property set --apihost $masterIP:31001
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP

echo "Setting the path to binaries"
echo -e "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bashrc
echo "alias canary='python3 $HOME/canary/canary.py'" >> $HOME/.bashrc

helm status owdev

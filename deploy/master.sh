#!/usr/bin/env bash

echo "Configuration of master node starting..."

apt-get update
apt-get install -y docker.io
printf '[\u2713]\tDocker installation completed\n'
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

add-apt-repository main
apt-get update
apt-get install -y kubelet kubeadm kubernetes-cni
apt-get install -y kubectl
printf '[\u2713]\tKubernetes,  kubeadm and kubeclt installation completed\n'

echo "Cluster creation in progress..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf # works if root
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
printf '[\u2713]\tCluster created\n'

# Helm installation
echo "Helm installation in progress..."
wget https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz
tar -xvf helm-v2.16.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
printf '[\u2713]\tHelm installed\n'

echo "wsk installation in progress..."
wget https://github.com/apache/openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-386.tgz
tar -xvf OpenWhisk_CLI-latest-linux-386.tgz
sudo mv wsk /usr/local/bin/wsk
printf '[\u2713]\twsk installed\n'
echo "Please log into the each worker node to complete worker configuration and join the cluster."
echo "kubectl label nodes <CORE_NODE_NAME> openwhisk-role=core
kubectl label nodes <INVOKER_NODE_NAME> openwhisk-role=invoker"

#!/usr/bin/env bash

echo "Configuration of worker nodes starting..."

apt-get update
apt-get install -y docker.io
printf '[\u2713]\tDocker installation completed\n'
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubernetes-cni
printf '[\u2713]\tKubernetes and Kubeadm installation completed\n'
printf "Enter Master\'s Public IP: "
read masterIP
printf "Enter cluster\'s auth token: "
read auth
printf "Enter cluster\'s discovery token hash: "
read disc

kubeadm join $masterIP:6443 --token $auth --discovery-token-ca-cert-hash 'sha256:'$disc

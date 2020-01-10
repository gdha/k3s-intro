# Build a Kubernetes cluster using k3s via Ansible.

Original Author: https://github.com/itwars
Modified by Gratien D'haese

## K3s Ansible Playbook

Build a Kubernetes cluster using Ansible with k3s. The goal is easily install a Kubernetes cluster on machines running:

- [X] Debian 
- [X] Ubuntu 
- [ ] CentOS 

on processor architecture:

- [X] x64
- [X] arm64
- [X] armhf

## System requirements:

Deployment environment must have Ansible 2.4.0+
Master and nodes must have passwordless SSH access

## Usage

Add the system information gathered above into a file called hosts.ini. For example:

```
[master]
192.168.33.11

[node]
192.168.33.[12:13]

[k3s-cluster:children]
master
node
```

Start provisioning of the cluster using the following command:

```
ansible-playbook site.yml
```

## Kubeconfig

To get access to your **Kubernetes** cluster just scp debian@master_pi:~/kube/config ~/.kube/config

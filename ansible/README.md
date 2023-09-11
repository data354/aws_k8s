# **Rke2 Setup GPT54 ENV**

## **Description**

This project is the setup of a production environment based on a kubernetes cluster for the deployment of a GPT54 stack. It automates the setup of a highly available k8s cluster on the RKE2 distribution and the installation of all software stacks.

**Features :**

- Scaling (up and down)
- Load balancer et proxy
- Nodes Security
- Backup (Etcd and PV)
- Multiple OS family (Debian and Redhat)
- Idempotence

## **Resources**

**Nodes**

- **GCP Env**

  - 1 e2-standard-2: 2vCPU, 8Gi RAM (master-ansible)
  - 3 e2-standard-8: 8vCPU, 32Gi RAM (data-plane-2, data-plane-3, data-plane-4)
  - 1 e2-standard-4: 4vCPU, 16Gi RAM (control-plane-1)
  
## **Prerequises**

**OS**

- Debian 11

**Network**

- All node must be in the same private network
- Nodes in the k8s cluster are not accessible via Internet
- All node have access to Internet via port 443
- The master ansible host (proxy & load balancer) is accessible via Internet

**Machine Access**

- The proxy (Load balancer) machine is accessible via SSH port 22
- All host in the k8s cluster are accessible via the proxy machine on port SSH port 22
- All machine must have a same user with root privileges

**Software**

- Python 3.8 
- Ansible [core 2.13.7]

## **Playbooks**

`prerequises.playbook.yml` : All apps, modules required for the stack deployment

`cluster.playbook.yml` : Contains the roles for the creatin of the cluster (Server and agent)

`client.playbook.yml` : Contains locak software to manage cluster

`apps.playbook.yml` : Contains the differents applications of the stack to install

`main.playbook.yml` : Contains all previous playbooks and runs them in order.

## **Process**

1. If tou don't use proxy in your environment, set the common variable `use_proxy` to false (`roles/commun/default/main.yml`)
2. Copy the master ansible ip address in the commons variables `loadbalancer_public_address` (`roles/commun/default/main.yml`)
3. Test node connection : `ansible -i inventory.ini -m ping all`
4. Launch project : `ansible-playbook -i inventory.ini main.playbook.yml`

## **Test cluster**

```bash
# Get all nodes
kubectl get nodes -o wide

# Get nodes resource utilization
kubectl top nodes

# Get all pods
kubectl get pods -A -o wide

# Get pods resource utilization
kubectl top pods

# Get all failed pods
kubectl get pods -A --field-selector=status.phase=Failed

# Get all failed pods
kubectl get pods -A --field-selector=status.phase=Unknown
```

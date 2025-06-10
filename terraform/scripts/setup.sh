#!/bin/bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Retrieve SSH key from Key Vault
az login --identity
KEY_VAULT_NAME=$(hostname | cut -d'-' -f1-2 | tr '-' ' ')
PRIVATE_KEY=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name vm-ssh-private-key --query "value" -o tsv)

# Configure SSH
mkdir -p /home/azureuser/.ssh
echo "$PRIVATE_KEY" > /home/azureuser/.ssh/id_rsa
chmod 600 /home/azureuser/.ssh/id_rsa
chown azureuser:azureuser /home/azureuser/.ssh/id_rsa

# Install Minikube and dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Docker installation
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker azureuser

# Minikube installation
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Kubernetes tools
sudo snap install kubectl --classic
sudo snap install helm --classic

# Start Minikube
sudo -u azureuser minikube start --driver=docker
#!/bin/bash

# Update the apt package index and install necessary packages
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the apt package index again
sudo apt update

# Install Docker Engine, containerd, and Docker Compose
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify that Docker Engine is installed correctly by running the hello-world image
sudo docker run hello-world
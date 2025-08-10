# Django Book Catalog - Kubernetes Deployment

A Django REST API application for book management with PostgreSQL backend, containerized and deployed on Kubernetes.

## 📋 Prerequisites

Before deploying this application, ensure you have:

- **Linux** system (Ubuntu/Debian recommended)
- **Docker** installed and running
- **Git** for cloning the repository

## 🚀 Installation Steps

### Step 1: Install Docker (if not already installed)

```bash
# Update package list
sudo apt update

# Install Docker
sudo apt install -y docker.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Install kubectl

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to system path
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

### Step 3: Install k3d

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify installation
k3d version
```

### Step 4: Create Kubernetes Cluster

```bash
# Create k3d cluster with port mapping
k3d cluster create django-cluster --port "30000:30000@server:0"

# Verify cluster is running
kubectl get nodes
```

### Step 5: Clone Repository and Deploy

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/devops-camp.git
cd devops-camp/file2

# Deploy in order
kubectl apply -f configmap.yaml
kubectl apply -f postgre-deploy.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl apply -f nginx-deployment.yaml
kubectl apply -f clusterip.yaml
kubectl apply -f nodeport.yaml
```

### Step 6: Verify Deployment

```bash
# Check if all pods are running
kubectl get pods

# Check services
kubectl get services

# View application logs
kubectl logs -l service=nginx-server --tail=50
```

## 🌐 Access the Application

Once deployed, access your application at: **http://localhost:30000**

### API Endpoints:
- **GET /api/books/** - List all books
- **POST /api/books/** - Create a new book
- **GET /api/books/{id}/** - Get specific book details
- **PUT /api/books/{id}/** - Update specific book
- **DELETE /api/books/{id}/** - Delete specific book
- **GET /api/pod-info/** - Pod information (load balancing test)
- **GET /api/books/manage/** - Web UI for book management



## 🐛 Troubleshooting


### Check Application Status:
```bash
# Monitor pods
kubectl get pods -w

# Check deployment status
kubectl rollout status deployment/nginx-servers

# Scale application (optional)
kubectl scale deployment nginx-servers --replicas=5
```

## 🏗️ Architecture

The deployment consists of:
- **3 Django application pods** (load balanced)
- **1 PostgreSQL database pod**
- **NodePort service** (external access on port 30000)
- **ClusterIP service** (internal communication)
- **ConfigMap** (environment variables)

---

**Ready to deploy!** 🚀



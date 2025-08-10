# Django Book Catalog - Kubernetes Deployment

A Django REST API application for book management with PostgreSQL backend, containerized and deployed on Kubernetes with load balancing and high availability.

## ⚡ Quick Start

Deploy the entire application with just **one command**:

```bash
git clone https://github.com/YOUR-USERNAME/devops-camp.git
cd devops-camp
chmod +x setup.sh
./setup.sh
```

**That's it!** 🎉 Your Django Book Catalog will be running at `http://localhost:30000`

## 🚀 Features

- **Django 4.2.11** REST API for comprehensive book management
- **PostgreSQL 13** database with persistent storage
- **Kubernetes deployment** with 3 replicas for high availability
- **Automatic load balancing** across multiple application pods
- **ConfigMap** for centralized environment variable management
- **Docker containerization** for consistent deployments
- **Multiple service types** (NodePort and ClusterIP) for flexible access
- **Health checks** and pod information endpoints
- **Web UI** for easy book management

## 📋 Prerequisites

Before deploying this application, ensure you have:

- **Docker** installed and running
- **Kubernetes cluster** (minikube, k3d, kind, or cloud provider)
- **kubectl** configured to access your cluster
- **Git** for cloning the repository

## 🔧 One-Command Deployment

### 🚀 Quick Start (Recommended)

Deploy the entire application with just one command:

```bash
# Clone the repository and run setup
git clone https://github.com/YOUR-USERNAME/devops-camp.git
cd devops-camp
chmod +x setup.sh
./setup.sh
```

### 🧪 Test Your Environment First (Optional)

Validate your environment before deploying:

```bash
# Test your setup without deploying anything
chmod +x test-environment.sh
./test-environment.sh

# Or run setup in test mode (dry run)
./setup.sh --test
```

### 📋 What the Setup Script Does:
- ✅ Verifies your Kubernetes cluster connection
- ✅ Detects your cluster type (minikube, k3d, kind, Docker Desktop)
- ✅ Deploys PostgreSQL database
- ✅ Deploys Django application (3 replicas)  
- ✅ Creates all required services
- ✅ Waits for everything to be ready
- ✅ Provides environment-specific access instructions

### 🛠️ Manual Deployment (Advanced Users)

If you prefer to deploy manually or need to customize the deployment:

#### Step 1: Set up Kubernetes Cluster (if using k3d)
```bash
# Install k3d if not already installed
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create cluster with port mapping
k3d cluster create django-cluster --port "30000:30000@server:0"
```

#### Step 2: Deploy Components
```bash
cd devops-camp/file2

# Deploy in order
kubectl apply -f configmap.yaml
kubectl apply -f postgre-deploy.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl apply -f nginx-deployment.yaml
kubectl apply -f clusterip.yaml
kubectl apply -f nodeport.yaml
```

#### Step 3: Verify Deployment
```bash
# Check status
kubectl get pods
kubectl get services

# View logs
kubectl logs -l service=nginx-server --tail=50
```

## 🌐 Accessing the Application

### Option 1: NodePort Service (External Access)
Access the application at: **http://localhost:30000**

### Option 2: Port Forwarding (Alternative)
```bash
kubectl port-forward service/nginx-internal 8080:8000
```
Then access at: **http://localhost:8080**

### Option 3: Using Minikube (if using minikube)
```bash
minikube service nginx-node-port --url
```

## 📝 API Endpoints

Once the application is running, you can access these endpoints:

- **GET /api/books/** - List all books
- **POST /api/books/** - Create a new book
- **GET /api/books/{id}/** - Get specific book details
- **PUT /api/books/{id}/** - Update specific book
- **DELETE /api/books/{id}/** - Delete specific book
- **GET /api/health/** - Health check endpoint
- **GET /api/pod-info/** - Pod information (for load balancing testing)
- **GET /api/books/manage/** - Web UI for book management

### Example API Usage

```bash
# Health check
curl http://localhost:30000/api/health/

# List all books
curl http://localhost:30000/api/books/

# Create a new book
curl -X POST http://localhost:30000/api/books/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Sample Book", "author": "John Doe", "isbn": "1234567890"}'

# Get pod information (to see load balancing)
curl http://localhost:30000/api/pod-info/
```

## 🔍 Load Balancing Testing

To verify Kubernetes load balancing is working:

1. **Make multiple requests** to see different pods responding:
   ```bash
   for i in {1..10}; do curl http://localhost:30000/api/pod-info/; echo; done
   ```

2. **Access the web UI** at http://localhost:30000/api/books/manage/ and refresh multiple times

3. **Check current pod distribution**:
   ```bash
   kubectl get pods -o wide
   ```

## 🛠️ Development Setup

### Local Development with Docker Compose

For local development, you can use Docker Compose:

```bash
cd bookcatalog
docker-compose up --build
```

Access at: http://localhost:8000

### Building Custom Docker Image

If you need to modify the application:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/devops-camp.git
   cd devops-camp/bookcatalog
   ```

2. **Make your changes** to the Django code

3. **Build and tag the image**:
   ```bash
   docker build -t your-registry/bookcatalog:your-version .
   ```

4. **Push to your registry**:
   ```bash
   docker push your-registry/bookcatalog:your-version
   ```

5. **Update the deployment** to use your image:
   ```bash
   kubectl set image deployment/nginx-servers fethullah-container=your-registry/bookcatalog:your-version
   ```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### Pods not starting
```bash
kubectl describe pods
kubectl logs -l service=nginx-server
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Database connection issues
```bash
kubectl get pods -l app=postgres
kubectl logs -l app=postgres
kubectl describe service db
```

#### Service not accessible
```bash
kubectl get services
kubectl get endpoints
kubectl describe service nginx-node-port
```

#### ConfigMap issues
```bash
kubectl get configmap app-config -o yaml
kubectl describe configmap app-config
```

#### Image pull issues
```bash
kubectl describe pods | grep -i image
```

### Resource Requirements

If you encounter resource issues:

```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resources
kubectl top pods
```

## 🏗️ Architecture Overview

```
┌─────────────────────┐    ┌─────────────────────┐
│   NodePort Service  │    │  ClusterIP Service  │
│   (External Access) │    │  (Internal Access)  │
│   Port: 30000       │    │   Port: 8000        │
└─────────┬───────────┘    └─────────┬───────────┘
          │                          │
          └─────────┬──────────────────┘
                    │
          ┌─────────▼───────────┐
          │  Kubernetes        │
          │  Load Balancer     │
          └─────────┬───────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───▼───┐       ┌───▼───┐       ┌───▼───┐
│ Pod 1 │       │ Pod 2 │       │ Pod 3 │
│Django │       │Django │       │Django │
│ App   │       │ App   │       │ App   │
└───┬───┘       └───┬───┘       └───┬───┘
    │               │               │
    └───────────────┼───────────────┘
                    │
            ┌───────▼────────┐
            │  PostgreSQL    │
            │   Database     │
            │   Service: db  │
            └────────────────┘
```

## 📂 Configuration Files

### Kubernetes Resources

- **`configmap.yaml`** - Environment variables for both Django and PostgreSQL
- **`postgre-deploy.yaml`** - PostgreSQL database deployment and service
- **`nginx-deployment.yaml`** - Django application deployment (3 replicas)
- **`clusterip.yaml`** - Internal service for inter-pod communication
- **`nodeport.yaml`** - External service for user access

### Application Files

- **`Dockerfile`** - Multi-stage Docker image build
- **`docker-compose.yml`** - Local development setup
- **`requirements.txt`** - Python dependencies
- **`entrypoint.sh`** - Container startup script with health checks
- **`manage.py`** - Django management commands

## 🔐 Configuration Details

### Environment Variables (ConfigMap)

```yaml
DATABASE_HOST: "db"          # PostgreSQL service name
DATABASE_NAME: "books"       # Database name
DATABASE_USER: "books"       # Database user
DATABASE_PASSWORD: "books"   # Database password
POSTGRES_DB: "books"         # PostgreSQL database
POSTGRES_USER: "books"       # PostgreSQL user
POSTGRES_PASSWORD: "books"   # PostgreSQL password
```

### Service Configuration

- **Django App**: Runs on port 8000 inside containers
- **PostgreSQL**: Runs on port 5432 inside container
- **NodePort**: Exposes app on port 30000 on cluster nodes
- **ClusterIP**: Internal communication on port 8000

## 📊 Monitoring and Scaling

### Check Application Health
```bash
# Check deployment status
kubectl rollout status deployment/nginx-servers

# Monitor pods
kubectl get pods -w

# Check resource usage
kubectl top pods
```

### Scaling the Application
```bash
# Scale up to 5 replicas
kubectl scale deployment nginx-servers --replicas=5

# Scale down to 2 replicas
kubectl scale deployment nginx-servers --replicas=2
```

## 🔄 Updates and Maintenance

### Rolling Updates
```bash
# Update to new image version
kubectl set image deployment/nginx-servers fethullah-container=ghcr.io/fethullahcucu/devops_camp/bookcatalog:v1.0.8

# Check rollout status
kubectl rollout status deployment/nginx-servers

# Rollback if needed
kubectl rollout undo deployment/nginx-servers
```

### Database Maintenance
```bash
# Access PostgreSQL directly
kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath="{.items[0].metadata.name}") -- psql -U books -d books
```

## 🧹 Cleanup

### One-Command Cleanup
```bash
# Remove all resources
chmod +x cleanup.sh
./cleanup.sh
```

### Manual Cleanup
To remove all resources manually:

```bash
# Delete all application resources
kubectl delete -f file2/nodeport.yaml
kubectl delete -f file2/clusterip.yaml  
kubectl delete -f file2/nginx-deployment.yaml
kubectl delete -f file2/postgre-deploy.yaml
kubectl delete -f file2/configmap.yaml

# Or delete everything at once
kubectl delete -f file2/
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review the Kubernetes logs: `kubectl logs -l service=nginx-server`
3. Open an issue on GitHub with detailed error messages

---

**Happy Deploying! 🚀**

### Clean reset
```bash
sudo k3d cluster delete devops
sudo k3d cluster create devops --port '80:80@loadbalancer' --port '443:443@loadbalancer' --wait
```
To reset the database, also delete the PVC (will erase data):
```bash
sudo kubectl delete pvc postgres-pvc
```

### Troubleshooting
- Cannot access from Windows:
  - Ensure hosts entry for `bookcatalog.local` points to `127.0.0.1` and run `ipconfig /flushdns`.
  - Verify cluster ports were mapped when creating the cluster (80/443 at loadbalancer).
  - Check Ingress is admitted and points to `service/django-app` port 8000:
    ```bash
    sudo kubectl get ingress -o wide
    sudo kubectl describe ingress django-ingress
    ```
  - Test from WSL:
    ```bash
    sudo curl -H 'Host: bookcatalog.local' http://127.0.0.1/
    ```
- App not starting:
  - `sudo kubectl logs deploy/django-app --tail=200`
  - `sudo kubectl describe deploy/django-app` and check image availability and environment variables
- Postgres issues:
  - `sudo kubectl logs deploy/postgres --tail=200`
  - Recreate PVC if you want a clean DB: `sudo kubectl delete pvc postgres-pvc`



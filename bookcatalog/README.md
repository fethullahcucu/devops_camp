# Django Book Catalog - Kubernetes Deployment

A Django REST API application with PostgreSQL backend, containerized and deployed on Kubernetes with load balancing.

## 🚀 Features

- Django 4.2.11 REST API for book management
- PostgreSQL 13 database
- Kubernetes deployment with 3 replicas
- Load balancing across multiple pods
- ConfigMap for centralized environment variable management
- Docker containerization
- NodePort and ClusterIP services

## 📋 Prerequisites

Before deploying this application, ensure you have:

- **Docker** installed and running
- **Kubernetes cluster** (k3d, minikube, or any K8s cluster)
- **kubectl** configured to access your cluster
- **Git** for cloning the repository

## 🔧 Deployment Steps

### Quick Deployment (Recommended)

You can deploy this application **without cloning the repository** since the Docker image contains all the code. You only need the Kubernetes YAML files:

#### Option 1: Download YAML files individually
```bash
# Create a directory for the deployment
mkdir django-book-catalog
cd django-book-catalog

# Download the required YAML files
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/devops-camp/main/k8s_yamls/file2/postgre-deploy.yaml
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/devops-camp/main/k8s_yamls/file2/configmap.yaml
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/devops-camp/main/k8s_yamls/file2/nginx-deployment.yaml
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/devops-camp/main/k8s_yamls/file2/clusterip.yaml
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/devops-camp/main/k8s_yamls/file2/nodeport.yaml
```

#### Option 2: Clone the full repository (for development)
```bash
git clone <your-repository-url>
cd devops-camp
```

### 1. Set up Kubernetes Cluster (if using k3d)

```bash
# Install k3d if not already installed
k3d cluster create mycluster --port "30000:30000@server:0"
```

### 2. Deploy PostgreSQL Database

```bash
kubectl apply -f postgre-deploy.yaml
```

### 3. Create ConfigMap for Environment Variables

```bash
kubectl apply -f configmap.yaml
```

### 4. Deploy the Django Application

```bash
kubectl apply -f nginx-deployment.yaml
```

### 5. Create Services for External Access

```bash
# Create ClusterIP service (internal)
kubectl apply -f clusterip.yaml

# Create NodePort service (external access)
kubectl apply -f nodeport.yaml
```

### 6. Verify Deployment

```bash
# Check if all pods are running
kubectl get pods

# Check services
kubectl get services

# Check logs
kubectl logs -l service=nginx-server
```

## 🌐 Accessing the Application

### Option 1: NodePort Service (Recommended)
Access the application at: **http://localhost:30000**

### Option 2: Port Forwarding
```bash
kubectl port-forward service/nginx-internal 8080:8000
```
Then access at: **http://localhost:8080**

## 🛠️ Building Your Own Docker Image (For Development)

**Note:** This section is only needed if you want to modify the source code. For deployment, the pre-built image is automatically pulled.

If you want to modify the code and build your own image:

1. **Clone the repository (for source code access):**
```bash
git clone <your-repository-url>
cd devops-camp/bookcatalog
```

2. **Make your changes** to the Django code

3. **Build the Docker image:**
```bash
docker build -t your-registry/bookcatalog:your-version .
```

4. **Push to your registry:**
```bash
docker push your-registry/bookcatalog:your-version
```

5. **Update the deployment:**
Edit `nginx-deployment.yaml` and change the image reference:
```yaml
- image: your-registry/bookcatalog:your-version
```

6. **Apply the changes:**
```bash
kubectl apply -f nginx-deployment.yaml
kubectl rollout restart deployment nginx-servers
```

## 📝 API Endpoints

- **GET /api/books/** - List all books
- **POST /api/books/** - Create a new book
- **GET /api/books/{id}/** - Get specific book
- **PUT /api/books/{id}/** - Update specific book
- **DELETE /api/books/{id}/** - Delete specific book
- **GET /api/health/** - Health check
- **GET /api/pod-info/** - Pod information (for load balancing testing)
- **GET /api/books/manage/** - Web UI for book management

## 🔍 Load Balancing Testing

To see Kubernetes load balancing in action:

1. **Access via NodePort** (http://localhost:30000) and refresh multiple times
2. **Check pod information** displayed on the web interface
3. **Make multiple API calls** to see different pods responding

## 🐛 Troubleshooting

### Pods not starting
```bash
kubectl describe pods
kubectl logs <pod-name>
```

### Database connection issues
```bash
kubectl get pods -l app=postgres
kubectl logs <postgres-pod-name>
```

### Service not accessible
```bash
kubectl get services
kubectl get endpoints
```

### ConfigMap issues
```bash
kubectl get configmap app-config -o yaml
```

## 🏗️ Architecture

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
          │  Load Balancer     │
          │  (Kubernetes)      │
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
            │   (Pod)        │
            └────────────────┘
```

## 📂 Configuration Files

- **nginx-deployment.yaml** - Django app deployment (3 replicas)
- **postgre-deploy.yaml** - PostgreSQL database deployment
- **configmap.yaml** - Environment variables configuration
- **clusterip.yaml** - Internal service configuration
- **nodeport.yaml** - External service configuration
- **Dockerfile** - Docker image configuration
- **requirements.txt** - Python dependencies

## 🔐 Environment Variables

The application uses these environment variables (managed via ConfigMap):

- `DATABASE_HOST=db`
- `DATABASE_NAME=books`
- `DATABASE_USER=books` 
- `DATABASE_PASSWORD=books`
- `POSTGRES_DB=books`
- `POSTGRES_USER=books`
- `POSTGRES_PASSWORD=books`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

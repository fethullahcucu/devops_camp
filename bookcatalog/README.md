# BookCatalog API

A Django REST API application for managing a book catalog with full CRUD operations, containerized with Docker and deployable on Kubernetes.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [API Endpoints](#api-endpoints)
- [Docker Setup](#docker-setup)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Development](#development)
- [Testing](#testing)

## ✨ Features

- **CRUD Operations**: Complete Create, Read, Update, Delete functionality for books
- **REST API**: Built with Django REST Framework
- **PostgreSQL Integration**: Production-ready database support
- **Docker Support**: Containerized application with docker-compose
- **Kubernetes Ready**: Complete K8s manifests for production deployment
- **Health Check**: Built-in health endpoint for monitoring
- **Web Interface**: HTML template for book management

## 🛠 Tech Stack

- **Backend**: Django 5.2.3, Django REST Framework 3.16.0
- **Database**: PostgreSQL 17.5
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes
- **Testing**: pytest, pytest-django
- **Environment**: Python 3.13

## 📁 Project Structure

```
bookcatalog/
├── api/                          # Django app for API
│   ├── models.py                 # Book model definition
│   ├── serializers.py            # DRF serializers
│   ├── views.py                  # API views and endpoints
│   ├── urls.py                   # API URL routing
│   ├── tests/                    # API tests
│   └── templates/                # HTML templates
├── bookcatalog/                  # Django project settings
│   ├── settings.py               # Project configuration
│   ├── urls.py                   # Main URL routing
│   └── wsgi.py                   # WSGI configuration
├── k8s_yamls/projects_file/      # Kubernetes manifests
│   ├── django-deployment.yaml    # Django app deployment
│   ├── django-nodeport.yaml      # NodePort service
│   ├── django-ingress.yaml       # Ingress configuration
│   ├── postgres-deployment.yaml  # PostgreSQL deployment
│   └── nginx-ingress-controller.yaml
├── docker-compose.yml            # Docker Compose configuration
├── Dockerfile                    # Docker image definition
├── requirements.txt              # Python dependencies
├── entrypoint.sh                 # Container startup script
└── manage.py                     # Django management script
```

## 🚀 Quick Start

### Prerequisites

- Python 3.13+
- Docker and Docker Compose
- Kubernetes cluster (for K8s deployment)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bookcatalog
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run migrations**
   ```bash
   python manage.py migrate
   ```

4. **Start the development server**
   ```bash
   python manage.py runserver
   ```

The API will be available at `http://localhost:8000`

## 🔗 API Endpoints

### Health Check
- `GET /health/` - Health check endpoint

### Books API
- `GET /api/books/` - List all books
- `POST /api/books/` - Create a new book
- `PUT /api/books/` - Update a book (requires `id` in request body)
- `DELETE /api/books/` - Delete a book (requires `id` in request body)

### Book Model Fields
```json
{
  "id": "integer (read-only)",
  "title": "string (max 255 chars)",
  "description": "string (optional)",
  "author": "string (max 255 chars)",
  "new_field": "string (max 255 chars, default: 'new_field')",
  "created_at": "datetime (auto-generated)"
}
```

### Example API Usage

**Create a book:**
```bash
curl -X POST http://localhost:8000/api/books/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "The Great Gatsby",
    "description": "A classic American novel",
    "author": "F. Scott Fitzgerald"
  }'
```

**Get all books:**
```bash
curl http://localhost:8000/api/books/
```

**Update a book:**
```bash
curl -X PUT http://localhost:8000/api/books/ \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "title": "Updated Title"
  }'
```

## 🐳 Docker Setup

### Using Docker Compose (Recommended)

1. **Build and start services**
   ```bash
   docker-compose up --build
   ```

2. **Run in detached mode**
   ```bash
   docker-compose up -d
   ```

3. **Stop services**
   ```bash
   docker-compose down
   ```

The application will be available at `http://localhost:8000`

### Docker Services

- **app**: Django application (Port 8000)
- **db**: PostgreSQL database
- **Persistent storage**: `pg_data` volume for database persistence

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_NAME` | `books` | PostgreSQL database name |
| `DATABASE_USER` | `books` | PostgreSQL username |
| `DATABASE_PASSWORD` | `books` | PostgreSQL password |
| `DATABASE_HOST` | `db` | Database host |
| `DEVELOPMENT_MODE` | `false` | Development mode flag |

## ☸️ Kubernetes Deployment

### 🚀 Deploy from Zero in New Environment

This section provides a complete guide to deploy the BookCatalog application in a fresh Kubernetes environment.

#### Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured and connected to your cluster
- Docker installed for building images

#### Step 1: Verify Kubernetes Cluster

```bash
# Check cluster connection
kubectl cluster-info

# Check nodes
kubectl get nodes

# Create namespace (optional but recommended)
kubectl create namespace bookcatalog
kubectl config set-context --current --namespace=bookcatalog
```

#### Step 2: Build and Load Docker Image

```bash
# Navigate to the bookcatalog directory
cd bookcatalog

# Build the Docker image
docker build -t bookcatalog:latest .

# For minikube: Load image into minikube
minikube image load bookcatalog:latest

# For kind: Load image into kind cluster
kind load docker-image bookcatalog:latest

# For cloud providers: Push to registry
# docker tag bookcatalog:latest your-registry/bookcatalog:latest
# docker push your-registry/bookcatalog:latest
```

#### Step 3: Deploy PostgreSQL Database

```bash
# Deploy PostgreSQL with PVC and Service
kubectl apply -f k8s_yamls/projects_file/postgres-deployment.yaml

# Verify PostgreSQL deployment
kubectl get pods -l app=postgres
kubectl get pvc postgres-pvc
kubectl get svc postgres
```

#### Step 4: Wait for PostgreSQL to be Ready

```bash
# Wait for PostgreSQL pod to be running
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Check PostgreSQL logs (optional)
kubectl logs -l app=postgres
```

#### Step 5: Deploy Django Application

```bash
# Deploy Django app with 5 replicas
kubectl apply -f k8s_yamls/projects_file/django-deployment.yaml

# Verify Django deployment
kubectl get deployment django-app
kubectl get pods -l app=django-app
kubectl get svc django-app
```

#### Step 6: Wait for Django Pods to be Ready

```bash
# Wait for all Django pods to be ready
kubectl wait --for=condition=ready pod -l app=django-app --timeout=300s

# Check Django logs
kubectl logs -l app=django-app --tail=50
```

#### Step 7: Expose the Application

**Option A: NodePort Service (Recommended for testing)**
```bash
# Create NodePort service
kubectl apply -f k8s_yamls/projects_file/django-nodeport.yaml

# Get the NodePort
kubectl get svc django-app-nodeport

# For minikube, get the service URL
minikube service django-app-nodeport --url
```

**Option B: Ingress (For production)**
```bash
# Apply ingress configuration
kubectl apply -f k8s_yamls/projects_file/django-ingress.yaml

# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
echo "$(minikube ip) bookcatalog.local" | sudo tee -a /etc/hosts
```

#### Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all

# Test health endpoint
curl http://<node-ip>:30080/health/

# Test API endpoint
curl http://<node-ip>:30080/api/books/
```

#### Step 9: Run Database Migrations (If needed)

```bash
# Get Django pod name
DJANGO_POD=$(kubectl get pods -l app=django-app -o jsonpath="{.items[0].metadata.name}")

# Run migrations
kubectl exec -it $DJANGO_POD -- python manage.py migrate

# Create superuser (optional)
kubectl exec -it $DJANGO_POD -- python manage.py createsuperuser
```

### 🛠 Troubleshooting

#### Common Issues and Solutions

**1. ImagePullBackOff Error**
```bash
# Check if image exists in cluster
kubectl describe pod <pod-name>

# For minikube: Ensure image is loaded
minikube image ls | grep bookcatalog

# For kind: Ensure image is loaded
docker exec -it kind-control-plane crictl images | grep bookcatalog
```

**2. Database Connection Issues**
```bash
# Check PostgreSQL service
kubectl get svc postgres

# Test database connection from Django pod
kubectl exec -it <django-pod> -- nc -zv postgres 5432
```

**3. Pod CrashLoopBackOff**
```bash
# Check pod logs
kubectl logs <pod-name> --previous

# Describe pod for events
kubectl describe pod <pod-name>
```

**4. Service Not Accessible**
```bash
# Check service endpoints
kubectl get endpoints

# For minikube: Get service URL
minikube service list

# Port forward for testing
kubectl port-forward svc/django-app 8000:8000
```

### 🧹 Cleanup

To remove all resources:
```bash
# Delete all resources
kubectl delete -f k8s_yamls/projects_file/

# Delete PVC (this will delete data!)
kubectl delete pvc postgres-pvc

# Delete namespace (if created)
kubectl delete namespace bookcatalog
```

### Quick Deploy Commands

For experienced users, here's a one-liner deployment:

```bash
# Build and deploy everything
docker build -t bookcatalog:latest . && \
minikube image load bookcatalog:latest && \
kubectl apply -f k8s_yamls/projects_file/ && \
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s && \
kubectl wait --for=condition=ready pod -l app=django-app --timeout=300s && \
echo "Deployment complete! Access at: $(minikube service django-app-nodeport --url)"
```

### Kubernetes Resources

#### PostgreSQL Deployment
- **PersistentVolumeClaim**: 1Gi storage for database
- **Deployment**: Single replica PostgreSQL 17.5 container
- **Service**: ClusterIP service on port 5432

#### Django Deployment
- **Deployment**: 5 replicas of the Django application
- **Image**: `bookcatalog:latest`
- **Port**: 8000
- **Environment**: Connected to PostgreSQL service

#### Services
- **NodePort**: Exposes Django app on port 30080
- **Ingress**: Routes traffic from `bookcatalog.local` to the app

### Access the Application

- **NodePort**: `http://<node-ip>:30080`
- **Ingress**: `http://bookcatalog.local` (add to `/etc/hosts` if needed)

## 💻 Development

### Running Tests

```bash
# Run all tests
python -m pytest

# Run specific test file
python -m pytest api/tests/test_views.py

# Run with coverage
python -m pytest --cov=api
```

### Database Operations

```bash
# Make migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Shell access
python manage.py shell
```

### Django Extensions

The project includes `django-extensions` for additional management commands:

```bash
# Enhanced shell with IPython
python manage.py shell_plus

# Show all URLs
python manage.py show_urls
```

## 🧪 Testing

The project uses pytest with Django integration:

- Test configuration: `pytest.ini`
- Test location: `api/tests/`
- Test database: Separate test database created automatically

### Test Coverage

Current test coverage includes:
- API endpoint functionality
- Model validation
- Serializer behavior

## 🔧 Configuration

### Django Settings

Key configuration in `bookcatalog/settings.py`:

- **Database**: PostgreSQL with environment variable support
- **REST Framework**: Configured for API development
- **Static Files**: Configured for production deployment
- **Debug**: Controlled by environment variables

### Environment Variables

Create a `.env` file for local development:

```env
DATABASE_NAME=books
DATABASE_USER=books
DATABASE_PASSWORD=books
DATABASE_HOST=localhost
DEVELOPMENT_MODE=true
```

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions:

- Create an issue in the repository
- Check the [Django documentation](https://docs.djangoproject.com/)
- Review [Django REST Framework docs](https://www.django-rest-framework.org/)

---

**Happy Coding! 🚀**

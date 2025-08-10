#!/bin/bash

# Django Book Catalog - One-Click Setup Script
# This script will deploy the entire application on Kubernetes

set -e  # Exit on any error

# Parse command line arguments
TEST_MODE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TEST_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --test      Run in test mode (dry run)"
            echo "  --verbose   Enable verbose output"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 Django Book Catalog - Kubernetes Setup"
echo "=========================================="

if [[ "$TEST_MODE" == true ]]; then
    echo "🧪 Running in TEST MODE - no actual deployment will occur"
    echo ""
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    echo ""
    echo "Installation instructions:"
    echo "  macOS: brew install kubectl"
    echo "  Linux: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "  Windows: choco install kubernetes-cli"
    exit 1
fi

# Check if we can connect to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster."
    echo ""
    echo "Please ensure you have one of the following:"
    echo "  - minikube: minikube start"
    echo "  - k3d: k3d cluster create my-cluster --port '30000:30000@server:0'"
    echo "  - kind: kind create cluster"
    echo "  - Docker Desktop with Kubernetes enabled"
    echo "  - A cloud Kubernetes cluster (EKS, GKE, AKS) configured"
    echo ""
    echo "Current kubectl context: $(kubectl config current-context 2>/dev/null || echo 'none')"
    exit 1
fi

# Detect the Kubernetes environment
K8S_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
print_success "Connected to Kubernetes cluster: $K8S_CONTEXT"

# Check if this is minikube and warn about NodePort access
if [[ "$K8S_CONTEXT" == *"minikube"* ]]; then
    MINIKUBE_DETECTED=true
    print_warning "Minikube detected - you may need to use 'minikube service' for access"
elif [[ "$K8S_CONTEXT" == *"k3d"* ]]; then
    K3D_DETECTED=true
    print_status "k3d detected - NodePort should work on localhost"
elif [[ "$K8S_CONTEXT" == *"kind"* ]]; then
    KIND_DETECTED=true
    print_warning "kind detected - you may need port-forwarding for access"
elif [[ "$K8S_CONTEXT" == *"docker-desktop"* ]]; then
    DOCKER_DESKTOP_DETECTED=true
    print_status "Docker Desktop detected - NodePort should work on localhost"
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_DIR="$SCRIPT_DIR/file2"

# Check if YAML files exist
if [ ! -d "$YAML_DIR" ]; then
    print_error "YAML files directory not found at: $YAML_DIR"
    print_error "Please ensure you're running this script from the devops-camp root directory"
    exit 1
fi

print_status "Found YAML files directory: $YAML_DIR"

# Deploy in the correct order
echo ""
print_status "Step 1/5: Creating ConfigMap..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would run: kubectl apply -f $YAML_DIR/configmap.yaml"
    print_success "ConfigMap would be created successfully"
else
    if kubectl apply -f "$YAML_DIR/configmap.yaml"; then
        print_success "ConfigMap created successfully"
    else
        print_error "Failed to create ConfigMap"
        exit 1
    fi
fi

echo ""
print_status "Step 2/5: Deploying PostgreSQL database..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would run: kubectl apply -f $YAML_DIR/postgre-deploy.yaml"
    print_success "PostgreSQL deployment would be created"
else
    if kubectl apply -f "$YAML_DIR/postgre-deploy.yaml"; then
        print_success "PostgreSQL deployment created"
    else
        print_error "Failed to deploy PostgreSQL"
        exit 1
    fi
fi

echo ""
print_status "Step 3/5: Waiting for PostgreSQL to be ready..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would wait for PostgreSQL pods"
    print_success "PostgreSQL would be ready"
else
    if kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s; then
        print_success "PostgreSQL is ready"
    else
        print_warning "PostgreSQL may still be starting. Continuing with deployment..."
    fi
fi

echo ""
print_status "Step 4/5: Deploying Django application..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would run: kubectl apply -f $YAML_DIR/nginx-deployment.yaml"
    print_success "Django application would be deployed"
else
    if kubectl apply -f "$YAML_DIR/nginx-deployment.yaml"; then
        print_success "Django application deployed"
    else
        print_error "Failed to deploy Django application"
        exit 1
    fi
fi

echo ""
print_status "Step 5/5: Creating services..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would run: kubectl apply -f $YAML_DIR/clusterip.yaml && kubectl apply -f $YAML_DIR/nodeport.yaml"
    print_success "Services would be created successfully"
else
    if kubectl apply -f "$YAML_DIR/clusterip.yaml" && kubectl apply -f "$YAML_DIR/nodeport.yaml"; then
        print_success "Services created successfully"
    else
        print_error "Failed to create services"
        exit 1
    fi
fi

echo ""
print_status "Waiting for Django application to be ready..."
if [[ "$TEST_MODE" == true ]]; then
    print_status "TEST MODE: Would wait for Django pods"
    print_success "Django application would be ready"
else
    if kubectl wait --for=condition=ready pod -l service=nginx-server --timeout=180s; then
        print_success "Django application is ready"
    else
        print_warning "Django application may still be starting..."
    fi
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo "======================================"
echo ""

# Show deployment status
print_status "Deployment Status:"
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""

# Get the NodePort for access
NODEPORT=$(kubectl get service nginx-node-port -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30000")

echo "🌐 Access your application:"
echo "=========================="
echo ""

# Provide different access instructions based on the environment
if [[ "$MINIKUBE_DETECTED" == true ]]; then
    echo "📱 Minikube Access:"
    echo "   minikube service nginx-node-port --url"
    echo "   Or use: kubectl port-forward service/nginx-internal 8080:8000"
    echo "   Then visit: http://localhost:8080"
elif [[ "$KIND_DETECTED" == true ]]; then
    echo "📱 kind Access (use port-forwarding):"
    echo "   kubectl port-forward service/nginx-internal 8080:8000"
    echo "   Then visit: http://localhost:8080"
elif [[ "$K3D_DETECTED" == true ]] || [[ "$DOCKER_DESKTOP_DETECTED" == true ]]; then
    echo "📱 Direct Access:"
    echo "   http://localhost:$NODEPORT"
else
    echo "📱 NodePort Access:"
    echo "   http://localhost:$NODEPORT"
    echo ""
    echo "   If localhost doesn't work, try:"
    echo "   - minikube service nginx-node-port --url (for minikube)"
    echo "   - kubectl port-forward service/nginx-internal 8080:8000"
    echo "   - Check your cluster's external IP"
fi

echo ""
echo "🔍 API Endpoints:"
if [[ "$KIND_DETECTED" == true ]]; then
    echo "   Health Check:    http://localhost:8080/api/health/ (after port-forward)"
    echo "   Books API:       http://localhost:8080/api/books/ (after port-forward)"
    echo "   Book Management: http://localhost:8080/api/books/manage/ (after port-forward)"
    echo "   Pod Info:        http://localhost:8080/api/pod-info/ (after port-forward)"
else
    echo "   Health Check:    http://localhost:$NODEPORT/api/health/"
    echo "   Books API:       http://localhost:$NODEPORT/api/books/"
    echo "   Book Management: http://localhost:$NODEPORT/api/books/manage/"
    echo "   Pod Info:        http://localhost:$NODEPORT/api/pod-info/"
fi
echo ""

echo "📋 Useful Commands:"
echo "=================="
echo ""
echo "View logs:           kubectl logs -l service=nginx-server --tail=50"
echo "Check pod status:    kubectl get pods"
echo "Scale application:   kubectl scale deployment nginx-servers --replicas=5"
echo "Delete deployment:   kubectl delete -f $YAML_DIR"
echo ""

echo "🔧 Troubleshooting:"
echo "==================="
echo ""
echo "If the application is not accessible:"
echo "1. Check cluster context: kubectl config current-context"
echo "2. Verify pods are running: kubectl get pods"
echo "3. Check service status: kubectl get service nginx-node-port"
echo "4. View application logs: kubectl logs -l service=nginx-server"
echo ""

if [[ "$MINIKUBE_DETECTED" == true ]]; then
    echo "Minikube specific:"
    echo "- Get service URL: minikube service nginx-node-port --url"
    echo "- Check minikube status: minikube status"
elif [[ "$KIND_DETECTED" == true ]]; then
    echo "kind specific:"
    echo "- Use port-forwarding: kubectl port-forward service/nginx-internal 8080:8000"
    echo "- Check kind clusters: kind get clusters"
elif [[ "$K3D_DETECTED" == true ]]; then
    echo "k3d specific:"
    echo "- Ensure port mapping was created with: --port '30000:30000@server:0'"
    echo "- Check cluster: k3d cluster list"
elif [[ "$DOCKER_DESKTOP_DETECTED" == true ]]; then
    echo "Docker Desktop specific:"
    echo "- Ensure Kubernetes is enabled in Docker Desktop settings"
    echo "- Try: kubectl get nodes"
fi

echo ""
echo "General debugging:"
echo "- Port forward: kubectl port-forward service/nginx-internal 8080:8000"
echo "- Check events: kubectl get events --sort-by=.metadata.creationTimestamp"
echo "- Describe pods: kubectl describe pods"
echo ""

print_success "Setup complete! Your Django Book Catalog is now running on Kubernetes! 🚀"

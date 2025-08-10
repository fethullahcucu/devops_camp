#!/bin/bash

# Django Book Catalog - Cleanup Script
# This script will remove all deployed resources

set -e  # Exit on any error

echo "🧹 Django Book Catalog - Cleanup"
echo "================================="

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
    print_error "kubectl is not installed."
    exit 1
fi

# Check if we can connect to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_DIR="$SCRIPT_DIR/file2"

# Check if YAML files exist
if [ ! -d "$YAML_DIR" ]; then
    print_error "YAML files directory not found at: $YAML_DIR"
    exit 1
fi

echo ""
print_warning "This will delete all Django Book Catalog resources from your Kubernetes cluster."
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
print_status "Removing Django Book Catalog resources..."

# Delete resources in reverse order
print_status "Deleting services..."
kubectl delete -f "$YAML_DIR/nodeport.yaml" --ignore-not-found=true
kubectl delete -f "$YAML_DIR/clusterip.yaml" --ignore-not-found=true

print_status "Deleting Django application..."
kubectl delete -f "$YAML_DIR/nginx-deployment.yaml" --ignore-not-found=true

print_status "Deleting PostgreSQL database..."
kubectl delete -f "$YAML_DIR/postgre-deploy.yaml" --ignore-not-found=true

print_status "Deleting ConfigMap..."
kubectl delete -f "$YAML_DIR/configmap.yaml" --ignore-not-found=true

echo ""
print_status "Checking for any remaining resources..."

# Check for any leftover pods
REMAINING_PODS=$(kubectl get pods -l app=postgres -o name 2>/dev/null || true)
REMAINING_DJANGO_PODS=$(kubectl get pods -l service=nginx-server -o name 2>/dev/null || true)

if [ ! -z "$REMAINING_PODS" ] || [ ! -z "$REMAINING_DJANGO_PODS" ]; then
    print_warning "Some pods may still be terminating..."
    kubectl get pods
else
    print_success "All pods have been removed"
fi

# Check for any leftover services
REMAINING_SERVICES=$(kubectl get services -l app=postgres -o name 2>/dev/null || true)
REMAINING_DJANGO_SERVICES=$(kubectl get services nginx-internal,nginx-node-port -o name 2>/dev/null || true)

if [ ! -z "$REMAINING_SERVICES" ] || [ ! -z "$REMAINING_DJANGO_SERVICES" ]; then
    print_warning "Some services may still exist..."
    kubectl get services
else
    print_success "All services have been removed"
fi

echo ""
print_success "Cleanup completed! 🎉"
echo ""
print_status "Optional: To also remove any persistent data, you can delete PVCs:"
echo "kubectl get pvc"
echo "kubectl delete pvc <pvc-name>"
echo ""
print_status "To redeploy the application, simply run: ./setup.sh"

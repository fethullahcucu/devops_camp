#!/bin/bash

# Django Book Catalog - Environment Test Script
# This script validates your environment before running setup.sh

echo "🔍 Django Book Catalog - Environment Validation"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to increment counters
pass_check() {
    ((CHECKS_PASSED++))
    print_pass "$1"
}

fail_check() {
    ((CHECKS_FAILED++))
    print_fail "$1"
}

warn_check() {
    print_warn "$1"
}

echo ""
print_check "Checking prerequisites..."
echo ""

# Check if kubectl is installed
print_check "1. kubectl installation"
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "unknown")
    pass_check "kubectl is installed (version: $KUBECTL_VERSION)"
else
    fail_check "kubectl is not installed"
    echo "         Install: https://kubernetes.io/docs/tasks/tools/"
fi

# Check kubectl cluster connection
print_check "2. Kubernetes cluster connection"
if kubectl cluster-info &> /dev/null; then
    CLUSTER_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
    pass_check "Connected to Kubernetes cluster: $CLUSTER_CONTEXT"
    
    # Detect cluster type
    if [[ "$CLUSTER_CONTEXT" == *"minikube"* ]]; then
        warn_check "Minikube detected - may need 'minikube service' for access"
    elif [[ "$CLUSTER_CONTEXT" == *"k3d"* ]]; then
        pass_check "k3d detected - good for local development"
    elif [[ "$CLUSTER_CONTEXT" == *"kind"* ]]; then
        warn_check "kind detected - may need port-forwarding for access"
    elif [[ "$CLUSTER_CONTEXT" == *"docker-desktop"* ]]; then
        pass_check "Docker Desktop detected - good for local development"
    else
        warn_check "Cluster type unknown - may need custom configuration"
    fi
else
    fail_check "Cannot connect to Kubernetes cluster"
    echo "         Try: minikube start, k3d cluster create, or kind create cluster"
fi

# Check if nodes are ready
print_check "3. Cluster nodes status"
if kubectl get nodes &> /dev/null; then
    READY_NODES=$(kubectl get nodes --no-headers | grep -c "Ready" || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l || echo "0")
    if [ "$READY_NODES" -gt 0 ]; then
        pass_check "$READY_NODES/$TOTAL_NODES nodes are ready"
    else
        fail_check "No nodes are ready"
    fi
else
    fail_check "Cannot check node status"
fi

# Check YAML files
print_check "4. Required YAML files"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_DIR="$SCRIPT_DIR/file2"

if [ -d "$YAML_DIR" ]; then
    pass_check "YAML directory exists: $YAML_DIR"
    
    # Check individual files
    REQUIRED_FILES=("configmap.yaml" "postgre-deploy.yaml" "nginx-deployment.yaml" "clusterip.yaml" "nodeport.yaml")
    MISSING_FILES=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$YAML_DIR/$file" ]; then
            pass_check "Found: $file"
        else
            fail_check "Missing: $file"
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        pass_check "All required YAML files are present"
    else
        fail_check "Missing ${#MISSING_FILES[@]} required files"
    fi
else
    fail_check "YAML directory not found: $YAML_DIR"
fi

# Check for potential port conflicts
print_check "5. Port availability (30000)"
if command -v netstat &> /dev/null; then
    if netstat -tuln 2>/dev/null | grep -q ":30000 "; then
        warn_check "Port 30000 appears to be in use"
    else
        pass_check "Port 30000 appears to be available"
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln 2>/dev/null | grep -q ":30000 "; then
        warn_check "Port 30000 appears to be in use"
    else
        pass_check "Port 30000 appears to be available"
    fi
else
    warn_check "Cannot check port 30000 availability (netstat/ss not found)"
fi

# Check if we have permissions to create resources
print_check "6. Kubernetes permissions"
if kubectl auth can-i create deployments &> /dev/null; then
    pass_check "Can create deployments"
else
    fail_check "Cannot create deployments - check RBAC permissions"
fi

if kubectl auth can-i create services &> /dev/null; then
    pass_check "Can create services"
else
    fail_check "Cannot create services - check RBAC permissions"
fi

if kubectl auth can-i create configmaps &> /dev/null; then
    pass_check "Can create configmaps"
else
    fail_check "Cannot create configmaps - check RBAC permissions"
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo "✅ Checks passed: $CHECKS_PASSED"
echo "❌ Checks failed: $CHECKS_FAILED"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    print_pass "Environment validation successful! 🎉"
    echo ""
    echo "You can now run: ./setup.sh"
    echo ""
    echo "Or test without deploying: ./setup.sh --test"
    exit 0
else
    print_fail "Environment validation failed!"
    echo ""
    echo "Please fix the issues above before running ./setup.sh"
    echo ""
    echo "Need help? Check the README.md file or the troubleshooting section."
    exit 1
fi

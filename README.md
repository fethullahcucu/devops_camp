## Bookcatalog on Kubernetes (WSL + k3d)

This guide provisions a clean local Kubernetes cluster in WSL (Ubuntu 22.04) using k3d, builds the Django app image, deploys Postgres and the app, and exposes it via Ingress.

### Prerequisites (inside WSL Ubuntu-22.04)
- Docker Engine running (Docker Desktop with WSL integration or native dockerd)
- kubectl
- k3d

Install examples (Ubuntu):
```bash
sudo apt update
sudo apt install -y curl ca-certificates
# kubectl (snap example)
sudo snap install kubectl --classic
# k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### 1) Create a fresh k3d cluster with host ports
```bash
sudo k3d cluster create devops \
  --port '80:80@loadbalancer' \
  --port '443:443@loadbalancer' \
  --wait

sudo kubectl config current-context   # should be k3d-devops
sudo kubectl get ns
```

### 2) Build the Django image
```bash
cd bookcatalog
sudo docker build -t bookcatalog:latest .
```

### 3) Import the image into k3d
```bash
sudo k3d image import bookcatalog:latest -c devops
```

### 4) Deploy Postgres and Django
```bash
cd /path/to/devops-camp   # repo root if you changed directories
sudo kubectl apply -f k8s_yamls/projects_file/postgres-deployment.yaml
sudo kubectl apply -f k8s_yamls/projects_file/django-deployment.yaml

# Wait until ready
sudo kubectl rollout status deploy/django-app
```

### 5) Expose via Ingress (Traefik is preinstalled in k3d)
```bash
sudo kubectl apply -f k8s_yamls/projects_file/django-ingress.yaml
sudo kubectl get ingress -o wide
```

On Windows, add a hosts entry so the browser resolves the host used by the Ingress:
- Open Notepad as Administrator
- Edit `C:\Windows\System32\drivers\etc\hosts` and add:
```
127.0.0.1 bookcatalog.local
```
- In an elevated PowerShell: `ipconfig /flushdns`

Now browse: `http://bookcatalog.local/`

### Alternative: NodePort access (no hosts entry)
```bash
sudo kubectl apply -f k8s_yamls/projects_file/django-nodeport.yaml
# Then open http://127.0.0.1:30080/
```

### Useful commands
```bash
# Cluster and workloads
sudo kubectl get all -A
sudo kubectl get deploy,svc,ingress,pvc
sudo kubectl logs deploy/django-app --tail=100

# Rebuild + reload app after code changes
cd bookcatalog && sudo docker build -t bookcatalog:latest .
sudo k3d image import bookcatalog:latest -c devops
sudo kubectl rollout restart deploy/django-app

# Inspect Ingress/Service
sudo kubectl describe ingress django-ingress
sudo kubectl get svc django-app -o wide

# Port-forward (debug)
sudo kubectl port-forward deploy/django-app 8000:8000
```

### Configuration notes
- The Django Deployment uses `image: bookcatalog:latest` and `imagePullPolicy: IfNotPresent`, so importing the local image is sufficient.
- Postgres runs with a `PersistentVolumeClaim` named `postgres-pvc`.
- Environment variables for Django (in `k8s_yamls/projects_file/django-deployment.yaml`):
  - `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_HOST`
  - `ALLOWED_HOSTS` (defaults to `*`)
  - `DEVELOPMENT_MODE` ("false" by default)

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



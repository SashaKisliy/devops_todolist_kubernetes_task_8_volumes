#!/bin/bash

# Deploy ToDo App with Kubernetes Volumes
# This script deploys all required resources for the ToDo application

set -e  # Exit on any error

echo "🚀 Starting deployment of ToDo App with Kubernetes Volumes..."

# Apply namespace first
echo "📦 Creating namespace..."
kubectl apply -f .infrastructure/namespace.yml

# Apply PersistentVolume
echo "💾 Creating PersistentVolume..."
kubectl apply -f .infrastructure/pv.yml

# Apply PersistentVolumeClaim
echo "📋 Creating PersistentVolumeClaim..."
kubectl apply -f .infrastructure/pvc.yml

# Apply ConfigMap
echo "⚙️  Creating ConfigMap..."
kubectl apply -f .infrastructure/confgiMap.yml

# Apply Secret
echo "🔐 Creating Secret..."
kubectl apply -f .infrastructure/secret.yml

# Apply Deployment
echo "🏗️  Creating Deployment..."
kubectl apply -f .infrastructure/deployment.yml

# Apply Services
echo "🌐 Creating Services..."
kubectl apply -f .infrastructure/clusterIp.yml
kubectl apply -f .infrastructure/nodeport.yml

# Apply HPA (if needed)
echo "📈 Creating HorizontalPodAutoscaler..."
kubectl apply -f .infrastructure/hpa.yml

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Checking deployment status..."
kubectl get pods -n todoapp
kubectl get pv
kubectl get pvc -n todoapp
echo ""
echo "🎉 ToDo App is ready! Access it via NodePort service."
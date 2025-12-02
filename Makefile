.PHONY: help clone-repo install-kubectl install-helm uninstall-minikube install-minikube setup-k8s verify-gpu test-gpu clean-gpu-test

# Default target
help:
	@echo "vLLM Production Stack - Kubernetes Setup Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup-env          - Setup environment prerequisites"
	@echo "  clone-repo         - Clone the official vllm production-stack repository"
	@echo "  setup-k8s          - Complete setup (kubectl + helm + minikube with GPU)"
	@echo "  install-kubectl    - Install kubectl CLI tool"
	@echo "  install-helm       - Install Helm package manager"
	@echo "  uninstall-minikube - Uninstall existing Minikube installation"
	@echo "  install-minikube   - Install Minikube with GPU support (uninstalls first)"
	@echo "  verify-gpu         - Verify GPU configuration in Kubernetes"
	@echo "  test-gpu           - Deploy and test a GPU workload"
	@echo "  clean-gpu-test     - Clean up GPU test pod"
	@echo "  minikube-status    - Check Minikube cluster status"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - GPU server with NVIDIA drivers installed"
	@echo "  - NVIDIA Container Toolkit installed"
	@echo "  - Docker installed and configured (no sudo required)"
	@echo ""
	@echo "Quick start: make setup-k8s"

# Setup environment prerequisites
setup-env:
	@echo "Setting up environment prerequisites..."
	@sudo apt install -y jq
	@pip install --upgrade pip setuptools

	@echo "Configuring git..."
	@git config --global user.email "abdullah.meda@gmail.com"
	@git config --global user.name "Abdullah Meda"

# Clone the repository
clone-repos:
	@echo "Cloning the repository..."
	@git clone https://github.com/ray-project/llmperf.git
	@git clone https://github.com/vllm-project/production-stack.git

	@pip install -e llmperf

# Complete Kubernetes setup
setup-k8s: install-kubectl install-helm install-minikube
	@echo "✅ Kubernetes environment setup complete!"
	@echo "Run 'make verify-gpu' to verify GPU configuration"

# Install kubectl
install-kubectl:
	@echo "📦 Installing kubectl..."
	cd production-stack/utils && bash install-kubectl.sh
	@echo "✅ kubectl installed successfully!"
	@kubectl version --client

# Install Helm
install-helm:
	@echo "📦 Installing Helm..."
	cd production-stack/utils && bash install-helm.sh
	@echo "✅ Helm installed successfully!"
	@helm version

# Uninstall existing Minikube installation (Ubuntu)
uninstall-minikube:
	@echo "🗑️  Checking for existing Minikube installation..."
	@if command -v minikube >/dev/null 2>&1; then \
		echo "Found Minikube installation. Uninstalling..."; \
		sudo apt remove -y minikube 2>/dev/null || true; \
		echo "✅ Minikube uninstalled successfully!"; \
	else \
		echo "No existing Minikube installation found."; \
	fi

# Install Minikube with GPU support
install-minikube: uninstall-minikube
	@echo "📦 Installing Minikube with GPU support..."
	@echo "Note: This will install Minikube and configure it for GPU workloads"
	@echo "Checking Docker group membership..."
	@groups | grep docker > /dev/null || (echo "❌ User not in docker group. Run: sudo usermod -aG docker $$USER && newgrp docker" && exit 1)
	cd production-stack/utils && bash install-minikube-cluster.sh
	@echo "✅ Minikube installed and configured successfully!"

# Check Minikube status
minikube-status:
	@echo "🔍 Checking Minikube status..."
	@minikube status

# Verify GPU configuration
verify-gpu:
	@echo "🔍 Verifying GPU configuration..."
	@echo ""
	@echo "1. Checking Minikube status:"
	@minikube status
	@echo ""
	@echo "2. Checking GPU resources in cluster:"
	@kubectl describe nodes | grep -i gpu || echo "⚠️  No GPU resources found"
	@echo ""
	@echo "✅ GPU verification complete!"

# Test GPU workload
test-gpu:
	@echo "🧪 Deploying GPU test workload..."
	@kubectl get pod gpu-test 2>/dev/null && (echo "⚠️  GPU test pod already exists. Run 'make clean-gpu-test' first." && exit 1) || true
	kubectl run gpu-test --image=nvidia/cuda:12.2.0-runtime-ubuntu22.04 --restart=Never -- nvidia-smi
	@echo "Waiting for pod to complete..."
	@sleep 5
	@kubectl wait --for=condition=Ready pod/gpu-test --timeout=120s 2>/dev/null || echo "Pod is running..."
	@echo ""
	@echo "📊 GPU test results:"
	@kubectl logs gpu-test 2>/dev/null || (echo "⚠️  Pod not ready yet. Check logs with: kubectl logs gpu-test" && exit 0)
	@echo ""
	@echo "✅ GPU test complete!"

# Clean up GPU test pod
clean-gpu-test:
	@echo "🧹 Cleaning up GPU test pod..."
	@kubectl delete pod gpu-test 2>/dev/null || echo "No gpu-test pod found"
	@echo "✅ Cleanup complete!"

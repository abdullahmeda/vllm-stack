# High-Performance vLLM Inference Cluster on Kubernetes

## Project Overview
This repository contains the Infrastructure-as-Code (IaC) and Kubernetes manifests for a production-grade LLM inference cluster. The goal is to deploy **Llama-3-8B** using **vLLM** with industry-standard observability and autoscaling patterns.

## Architecture (In Progress)
- **Engine:** vLLM (v0.6.3) with PagedAttention and Continuous Batching enabled.
- **Orchestration:** Kubernetes (K3s/EKS) with Helm charts.
- **Observability:** Prometheus & Grafana sidecars for tracking `num_requests_running` and `gpu_cache_usage`.
- **Load Balancing:** Prefix-aware routing to maximize KV-cache hits.

## Roadmap
- [ ] Configure `values.yaml` for NVIDIA H100/A100 optimization.
- [ ] Implement Helm Chart deployment.
- [ ] Set up Grafana Dashboards for Token Throughput (tok/s).
- [ ] Stress test using `llmperf`.

*Note: This is an active project demonstrating the implementation of the vLLM Production Stack.*

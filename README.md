# 12SOAT - Oficina Mecânica - Kubernetes Infrastructure

Infraestrutura Kubernetes (Minikube + Kong Gateway + New Relic).

## Stack
- Minikube (Kubernetes local)
- Kong Gateway OSS
- New Relic (monitoring)
- Terraform

## Estrutura
```
terraform/           - Infraestrutura como código
.github/workflows/   - CI/CD
```

## Setup

### 1. Pré-requisitos

```bash
# Instalar Minikube
brew install minikube

# Instalar kubectl
brew install kubectl

# Instalar Helm
brew install helm
```

### 2. Subir Cluster

```bash
minikube start --cpus=2 --memory=4096
```

### 3. Instalar Kong Gateway

```bash
helm repo add kong https://charts.konghq.com
helm install kong kong/kong -n kong --create-namespace
```

### 4. Instalar New Relic (Monitoring)

```bash
helm repo add newrelic https://helm-charts.newrelic.com
helm install newrelic-bundle newrelic/nri-bundle \
  --set global.licenseKey=$NEWRELIC_LICENSE_KEY \
  --set global.cluster=oficina-mecanica-local
```

## Secrets Necessários

- `NEWRELIC_LICENSE_KEY` - License key do New Relic

## Componentes

- **Minikube**: Cluster Kubernetes local
- **Kong Gateway**: API Gateway com validação JWT
- **New Relic**: APM + Observabilidade completa
- **Metrics Server**: Para HPA (Horizontal Pod Autoscaler)

# Oficina Mecânica - Infraestrutura Kubernetes

Infraestrutura Kubernetes com Kong Gateway e New Relic para API Gateway e observabilidade.

---

## 🎯 Propósito

Provisionar e gerenciar a infraestrutura Kubernetes incluindo API Gateway (Kong) com autenticação JWT e integração com observabilidade (New Relic).

---

## 🛠️ Tecnologias

- **Minikube** - Cluster Kubernetes local
- **Kong Gateway OSS** - API Gateway com plugins JWT
- **New Relic** - APM e monitoramento de infraestrutura
- **Helm** - Gerenciador de pacotes Kubernetes
- **Terraform** - Infraestrutura como código (planejado)
- **GitHub Actions** - CI/CD automático

---

## 📁 Estrutura

```
kong/
├── auth-ingress.yaml    - Ingress para Lambda de autenticação
├── lambda-service.yaml  - Service apontando para Lambda
├── app-ingress.yaml     - Ingress para aplicação NestJS
└── app-service.yaml     - Service da aplicação

.github/workflows/       - CI/CD (validação de manifestos)
```

---

## 🚀 Deploy

### **Pré-requisitos**

```bash
# macOS
brew install minikube kubectl helm

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### **1. Criar Cluster Minikube**

```bash
minikube start --cpus=2 --memory=3500 --driver=docker
minikube addons enable ingress
```

### **2. Instalar Kong Gateway**

```bash
helm repo add kong https://charts.konghq.com
helm repo update

helm install kong kong/kong \
  --namespace kong \
  --create-namespace \
  --set ingressController.installCRDs=false \
  --set proxy.type=NodePort
```

### **3. Instalar New Relic**

```bash
helm repo add newrelic https://helm-charts.newrelic.com
helm repo update

helm install newrelic-bundle newrelic/nri-bundle \
  --namespace newrelic \
  --create-namespace \
  --set global.licenseKey=$NEW_RELIC_LICENSE_KEY \
  --set global.cluster=oficina-mecanica-k8s \
  --set newrelic-infrastructure.privileged=true \
  --set ksm.enabled=true
```

### **4. Aplicar Manifestos Kong**

```bash
# Services e Ingress para Lambda de autenticação
kubectl apply -f kong/lambda-service.yaml
kubectl apply -f kong/auth-ingress.yaml

# Services e Ingress para aplicação NestJS
kubectl apply -f kong/app-service.yaml
kubectl apply -f kong/app-ingress.yaml
```

### **5. Verificar Deploy**

```bash
# Status dos componentes
kubectl get pods -n kong
kubectl get pods -n newrelic

# Services e Ingress
kubectl get svc,ingress -n default

# URL do Kong
minikube service kong-kong-proxy -n kong --url
```

---

## 🔐 Secrets Necessários

Configure no GitHub: **Settings → Secrets → Actions**

| Secret | Descrição |
|--------|-----------|
| `NEW_RELIC_LICENSE_KEY` | License key do New Relic |

---

## 📊 Arquitetura

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ HTTPS
       ▼
┌──────────────────┐
│  Kong Gateway    │
│  (API Gateway)   │
│  - Rate Limiting │
│  - JWT Auth      │
└────┬────────┬────┘
     │        │
     │        └──────────────────┐
     │                           │
     ▼                           ▼
┌────────────────┐    ┌──────────────────┐
│ Lambda Auth    │    │  NestJS App      │
│ (Serverless)   │    │  (Kubernetes)    │
│ - Valida CPF   │    │  - API REST      │
│ - Gera JWT     │    │  - New Relic APM │
└────────────────┘    └──────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │ Neon PostgreSQL │
                      └─────────────────┘
         ┌──────────────────┴───────────┐
         │                              │
         ▼                              ▼
┌─────────────────┐          ┌──────────────────┐
│  New Relic APM  │          │ New Relic Infra  │
│  (App metrics)  │          │ (K8s metrics)    │
└─────────────────┘          └──────────────────┘
```

---

## 🧪 Como Testar

### **Kong Gateway**

```bash
# Obter URL do Kong
KONG_URL=$(minikube service kong-kong-proxy -n kong --url | head -1)

# Testar endpoint de autenticação
curl $KONG_URL/auth -X POST \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}'

# Testar endpoint protegido (com JWT)
TOKEN="<jwt-token>"
curl $KONG_URL/ordens-servico \
  -H "Authorization: Bearer $TOKEN"
```

### **New Relic**

Acesse o dashboard: https://one.newrelic.com/

- **APM**: Aplicação NestJS
- **Infrastructure**: Métricas do cluster Kubernetes
- **Dashboards**: Custom metrics de ordens de serviço

---

## 🔗 Recursos

- **Kong Admin API**: http://localhost:8001 (via port-forward)
- **New Relic Dashboard**: https://one.newrelic.com/
- **Minikube Dashboard**: `minikube dashboard`
- **GitHub Actions**: https://github.com/<usuario>/12soat-oficina-infra-k8s/actions

---

## 📄 Licença

MIT - Tech Challenge 12SOAT Fase 3

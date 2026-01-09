# Oficina Mecânica - Infraestrutura Cloud

Infraestrutura AWS com Kong Gateway e New Relic para API Gateway e observabilidade.

## 🎯 Propósito

Provisionar infraestrutura na AWS (EC2 + Docker Compose) com Kong Gateway e monitoramento New Relic, permitindo deploy/destroy diário para economia de custos.

---

## 🛠️ Tecnologias

- **AWS EC2** - Instância t3.small (Ubuntu 22.04)
- **Docker Compose** - Orquestração de containers
- **Kong Gateway** - API Gateway
- **New Relic** - APM e monitoramento
- **Terraform** - Infraestrutura como código
- **Elastic IP** - IP público persistente

---

## 📊 Infraestrutura

```
AWS EC2 (t3.small)
├── Kong Gateway (porta 8000)
├── Aplicação NestJS (porta 3000)
└── Docker Compose
```

**Custo estimado:** ~$0.30/dia (~$4.50 em 15 dias com apply/destroy diário)

## 🚀 Deploy

### Pré-requisitos
- AWS CLI configurado
- Terraform instalado
- Chave SSH criada e importada na AWS
- Secrets: `NEON_DATABASE_URL`, `JWT_SECRET`, `NEW_RELIC_LICENSE_KEY`

### Deploy Completo

```bash
# 1. Configurar variáveis
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com seus valores

# 2. Deploy
terraform init
terraform apply

# Output: kong_url = "http://<IP>:8000"
```

### Workflow Diário (Economia de Custos)

**Iniciar trabalho:**
```bash
terraform apply -auto-approve
# Aguardar ~3 minutos para containers iniciarem
```

**Pausar trabalho:**
```bash
terraform destroy -auto-approve
# Elastic IP é mantido (mesmo IP público)
```

---

## 🧪 Teste

**URL pública:** http://100.51.158.94:8000

```bash
# Health check
curl http://100.51.158.94:8000/health

# Resposta esperada:
{"status":"ok","timestamp":"2026-01-09T18:04:03.133Z","environment":"production"}
```

---

## 📄 Arquitetura

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ HTTP
       ▼
┌──────────────────────┐
│   AWS EC2 (t3.small) │
│  ┌─────────────────┐ │
│  │  Kong Gateway   │ │ :8000
│  │  (Docker)       │ │
│  └────────┬────────┘ │
│           │          │
│           ▼          │
│  ┌─────────────────┐ │
│  │  NestJS App     │ │ :3000
│  │  (Docker)       │ │
│  │  - New Relic    │ │
│  └────────┬────────┘ │
└───────────┼──────────┘
            │
            ▼
   ┌─────────────────┐
   │ Neon PostgreSQL │
   └─────────────────┘
```

## 🔗 Repositórios Relacionados

- [12soat-oficina-app](https://github.com/cassiamartinelli-fc/12soat-oficina-app) - API NestJS
- [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth) - Lambda Auth
- [12soat-oficina-infra-database](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-database) - Neon PostgreSQL

---

## 📄 Licença

MIT - Tech Challenge 12SOAT Fase 3

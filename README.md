# Oficina Mecânica - Infraestrutura Cloud

Infraestrutura AWS com Kong Gateway e New Relic para API Gateway e observabilidade.

## 🎯 Propósito

Provisionar infraestrutura na AWS (EC2 + Docker Compose) com Kong Gateway e monitoramento New Relic.

## 🛠️ Tecnologias

- **AWS EC2** - Instância t3.small (Ubuntu 22.04)
- **Docker Compose** - Orquestração de containers
- **Kong Gateway** - API Gateway
- **New Relic** - APM e monitoramento
- **Terraform** - Infraestrutura como código
- **Elastic IP** - IP público persistente

## 📊 Infraestrutura

```
AWS EC2 (t3.small)
├── Kong Gateway (porta 8000)
├── Aplicação NestJS (porta 3000)
└── Docker Compose
```

## 🚀 Setup

A infraestrutura AWS (EC2 + Kong + New Relic) é provisionada via GitHub Actions.

**Passos para provisionar:**

1. Provisionar infraestrutura:
   ```
   Actions → Terraform AWS → Run workflow → apply
   ```
   Aguardar ~3 minutos para containers iniciarem.

2. Obter URL pública:
   ```
   Actions → Terraform AWS → Run workflow → output
   ```
   Copiar a URL do Kong Gateway exibida nos logs.

3. Testar:
   ```bash
   curl <URL_OBTIDA>/health
   ```

**Para provisionar localmente:**

📖 Ver [Documentação Terraform](terraform/README.md)

## ⚙️ Workflow (GitHub Actions)

### Terraform AWS

```
Actions → Terraform AWS → Run workflow
Escolher: plan | apply | output | destroy
```

- **plan** — Valida a configuração Terraform
- **apply** — Provisiona infraestrutura AWS (EC2 + Kong + Docker)
- **output** — Exibe URL pública atual do Kong Gateway
- **destroy** — Deleta a infraestrutura (economia de custos)

**Observação:** Execute `output` sempre que precisar da URL pública, pois o IP muda a cada ciclo destroy/apply.

## 🧪 Validação

```bash
# 1. Obter URL via workflow output ou terraform
terraform output -raw kong_url

# 2. Health check
curl <URL_OBTIDA>/health

# Resposta esperada:
{"status":"ok","timestamp":"...","environment":"production"}
```

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

## 🔐 CI/CD — Secrets e permissões

✅ **Todos os secrets já estão devidamente configurados neste repositório.**

**Secrets necessários (Settings → Secrets → Actions):**
- `AWS_ACCESS_KEY_ID` — AWS Access Key
- `AWS_SECRET_ACCESS_KEY` — AWS Secret Key
- `NEON_DATABASE_URL` — Connection string do PostgreSQL (Neon)
- `NEWRELIC_LICENSE_KEY` — License key do New Relic
- `JWT_SECRET` — Chave secreta para JWT

## 🔗 Recursos

- **Repositórios relacionados**:
  - [12soat-oficina-app](https://github.com/cassiamartinelli-fc/12soat-oficina-app)
  - [12soat-oficina-lambda-auth](https://github.com/cassiamartinelli-fc/12soat-oficina-lambda-auth)
  - [12soat-oficina-infra-database](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-database)

## 📄 Licença

MIT — Tech Challenge 12SOAT Fase 3
